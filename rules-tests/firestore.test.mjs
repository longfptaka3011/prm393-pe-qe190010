import {readFile} from 'node:fs/promises';
import {after, before, beforeEach, test} from 'node:test';
import assert from 'node:assert/strict';
import {initializeTestEnvironment, assertFails, assertSucceeds} from '@firebase/rules-unit-testing';
import {doc, setDoc, getDoc, getDocs, collection, query, where, updateDoc, deleteDoc, Timestamp, runTransaction} from 'firebase/firestore';

let env;
const idFor = (uid, name) => `${uid}_${Buffer.from(name.trim().toLowerCase(), 'utf8').toString('hex')}`;
const data = (uid = 'alice', name = 'Pho Bo') => ({id: idFor(uid, name), userId: uid, name, category: 'Dinner', difficulty: 'Easy', cookTime: 25, favorite: false, notes: '', createdAt: Timestamp.fromMillis(1000)});
const db = (uid = 'alice') => env.authenticatedContext(uid).firestore();
before(async () => {
  env = await initializeTestEnvironment({projectId: 'demo-recipebox', firestore: {rules: await readFile(new URL('../firestore.rules', import.meta.url), 'utf8')}});
});
beforeEach(async () => { await env.clearFirestore(); });
after(async () => { await env?.cleanup(); });

test('owner CRUD, scoped query, Unicode and slash names', async () => {
  const store = db(); const recipe = data('alice', 'Phở / bò'); const ref = doc(store, 'recipes', recipe.id);
  await assertSucceeds(setDoc(ref, recipe));
  await assertSucceeds(getDoc(ref));
  await assertSucceeds(getDocs(query(collection(store, 'recipes'), where('userId', '==', 'alice'))));
  await assertSucceeds(updateDoc(ref, {favorite: true, servings: 20, cookTime: 600}));
  await assertSucceeds(deleteDoc(ref));
});
test('transaction can read absent canonical target and create it', async () => {
  const store = db(); const recipe = data(); const ref = doc(store, 'recipes', recipe.id);
  await assertSucceeds(runTransaction(store, async tx => { assert.equal((await tx.get(ref)).exists(), false); tx.set(ref, recipe); }));
});
test('anonymous access and cross-user CRUD are denied', async () => {
  const recipe = data(); await setDoc(doc(db(), 'recipes', recipe.id), recipe);
  for (const store of [db('bob'), env.unauthenticatedContext().firestore()]) {
    const ref = doc(store, 'recipes', recipe.id);
    await assertFails(getDoc(ref)); await assertFails(updateDoc(ref, {favorite: true})); await assertFails(deleteDoc(ref));
    await assertFails(setDoc(doc(store, 'recipes', idFor('alice', 'Soup')), data('alice', 'Soup')));
    await assertFails(getDocs(collection(store, 'recipes')));
  }
});
test('direct invalid writes rejected regardless of form validation', async () => {
  const invalid = [
    {name: ''}, {name: '   '}, {name: 'a'.repeat(81)}, {category: 'Snack'}, {difficulty: 'Expert'},
    {cookTime: 0}, {cookTime: 601}, {cookTime: 1.5}, {cookTime: '25'}, {servings: 0}, {servings: 21}, {servings: 1.5}, {servings: null},
    {notes: 'a'.repeat(301)}, {favorite: 'true'}, {userId: 'bob'}, {id: 'wrong'}, {createdAt: 'today'}, {admin: true}
  ];
  for (const overrides of invalid) {
    const recipe = {...data(), ...overrides};
    await assertFails(setDoc(doc(db(), 'recipes', data().id), recipe));
  }
  for (const key of ['id','userId','name','category','difficulty','cookTime','favorite','notes','createdAt']) {
    const recipe = data(); delete recipe[key]; await assertFails(setDoc(doc(db(), 'recipes', data().id), recipe));
  }
});
test('canonical IDs stop case-insensitive duplicates under alternate document IDs', async () => {
  const original = data(); await setDoc(doc(db(), 'recipes', original.id), original);
  const duplicate = data('alice', 'pho bo');
  assert.equal(original.id, duplicate.id);
  for (const alternate of ['random-id', 'alice_pho-bo', original.id + '-2']) {
    await assertFails(setDoc(doc(db(), 'recipes', alternate), {...duplicate, id: alternate}));
  }
  // A create-only transaction rejects an existing canonical target, as in the app.
  const store = db();
  await assert.rejects(runTransaction(store, async tx => {
    const ref = doc(store, 'recipes', duplicate.id);
    if ((await tx.get(ref)).exists()) throw new Error('already-exists');
    tx.set(ref, duplicate);
  }), /already-exists/);
  const anotherOwner = data('bob', 'pho bo');
  await assertSucceeds(setDoc(doc(db('bob'), 'recipes', anotherOwner.id), anotherOwner));
});
test('atomic rename preserves date; cannot rename in-place or transfer ownership', async () => {
  const store = db(); const original = data(); const oldRef = doc(store, 'recipes', original.id);
  await setDoc(oldRef, original);
  await assertFails(updateDoc(oldRef, {name: 'Soup'}));
  await assertFails(updateDoc(oldRef, {userId: 'bob'}));
  await assertFails(updateDoc(oldRef, {createdAt: Timestamp.now()}));
  const renamed = data('alice', 'Soup');
  await assertSucceeds(runTransaction(store, async tx => { const target = doc(store, 'recipes', renamed.id); await tx.get(target); await tx.get(oldRef); tx.set(target, renamed); tx.delete(oldRef); }));
  assert.equal((await getDoc(oldRef)).exists(), false);
  assert.equal((await getDoc(doc(store, 'recipes', renamed.id))).data().name, 'Soup');
});
