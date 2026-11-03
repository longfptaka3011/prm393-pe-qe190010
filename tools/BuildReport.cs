using System;
using System.IO;
using System.Collections.Generic;
using System.Web.Script.Serialization;
using System.Runtime.InteropServices;

public class BuildReport {
  static dynamic word, doc, sel;
  static void Text(string text, int style, int align) {
    sel.Style = doc.Styles[style];
    sel.ParagraphFormat.Alignment = align;
    sel.Font.Color = 0;
    sel.TypeText(text);
    sel.TypeParagraph();
  }
  public static int Main(string[] args) {
    string root = Path.GetFullPath(args.Length > 0 ? args[0] : ".");
    var json = new JavaScriptSerializer();
    var account = json.Deserialize<Dictionary<string,object>>(File.ReadAllText(Path.Combine(root,".local/phone-test.json")));
    var release = json.Deserialize<Dictionary<string,object>>(File.ReadAllText(Path.Combine(root,"artifacts/release.json")));
    var sections = json.Deserialize<List<Dictionary<string,string>>>(File.ReadAllText(Path.Combine(root,"tools/report_sections.json")));
    bool draft = args.Length > 1 && args[1] == "--draft";
    if(draft) sections = sections.FindAll(item => File.Exists(Path.Combine(root,item["file"])));
    foreach(var item in sections) if(!File.Exists(Path.Combine(root,item["file"]))) throw new FileNotFoundException("Required evidence is missing: " + item["file"]);
    string output = Path.Combine(root,draft ? "artifacts/report-draft" : "submission/QE190010");
    string qa = Path.Combine(root,draft ? "artifacts/report-qa-draft" : "artifacts/report-qa");
    Directory.CreateDirectory(output); Directory.CreateDirectory(qa);
    try {
      word = Activator.CreateInstance(Type.GetTypeFromProgID("Word.Application"));
      word.Visible = false; word.DisplayAlerts = 0; word.AutomationSecurity = 3;
      doc = word.Documents.Add(); sel = word.Selection;
      doc.PageSetup.PaperSize = 7;
      doc.PageSetup.TopMargin = 43.2f; doc.PageSetup.BottomMargin = 43.2f;
      doc.PageSetup.LeftMargin = 50.4f; doc.PageSetup.RightMargin = 50.4f;
      foreach(int style in new int[]{-1,-2,-35,-63}) {
        doc.Styles[style].Font.Name = "Calibri";
        doc.Styles[style].Font.Color = 0;
        doc.Styles[style].ParagraphFormat.SpaceBefore = 0;
        doc.Styles[style].ParagraphFormat.SpaceAfter = 8;
      }
      doc.Styles[-1].Font.Size = 11;
      doc.Styles[-2].Font.Size = 16; doc.Styles[-2].Font.Bold = -1;
      doc.Styles[-63].Font.Size = 24; doc.Styles[-63].Font.Bold = -1;
      doc.Styles[-35].Font.Size = 10.5f;
      Text("RecipeBox Practical Exam Report", -63, 0);
      Text("PRM393 Fall 2026", -1, 0);
      Text("Student Code: QE190010",-1,0);
      Text("Full Name: Trần Nguyễn Bảo Long",-1,0);
      Text("GitHub Repository URL: https://github.com/longfptaka3011/prm393-pe-qe190010",-1,0);
      Text("APK Download Link: " + release["apkUrl"],-1,0);
      Text("Firebase Project ID: recipebox-qe190010-20261103",-1,0);
      Text("Test account email: " + account["TEST_EMAIL"],-1,0);
      Text("Test account password: " + account["TEST_PASSWORD"],-1,0);
      Text("Implementation and verification",-2,0);
      Text("RecipeBox is a Flutter Android application using Firebase Email/Password Authentication and Cloud Firestore. Recipes are private to each account. The application supports validated add and edit forms, favorite toggles, deletion with confirmation, combined filters, search and a summary of the displayed recipes.",-1,0);
      Text("The release APK was installed and verified on a physical 2201123C phone running Android 15. After a cold restart, the test account remains signed in with 4 recipes, 1 favorite and a total cooking time of 97 minutes. The application screenshots in this report were captured directly from that phone using ADB.",-1,0);
      Text("Validation: Flutter static analysis passed; 9 unit/widget tests and 6 Firestore Rules tests passed. The complete Firebase workflow also passed on the physical phone.",-1,0);
      int number=0;
      foreach(var item in sections) {
        sel.InsertBreak(7);
        Text((++number).ToString() + " " + item["heading"],-2,0);
        sel.Style = doc.Styles[-1]; sel.ParagraphFormat.Alignment = 1;
        sel.ParagraphFormat.SpaceBefore = 0; sel.ParagraphFormat.SpaceAfter = 6;
        sel.ParagraphFormat.KeepWithNext = -1;
        dynamic picture = sel.InlineShapes.AddPicture(Path.Combine(root,item["file"]),false,true);
        picture.LockAspectRatio = -1; picture.Width = 259.2f;
        picture.AlternativeText = item["caption"];
        sel.MoveRight(1,1); sel.TypeParagraph();
        sel.ParagraphFormat.KeepWithNext = 0;
        Text(item["caption"],-35,1);
      }
      doc.Repaginate();
      int pages=doc.ComputeStatistics(2);
      string docx=Path.Combine(output,"QE190010.docx");
      doc.SaveAs2(docx,12);
      doc.ExportAsFixedFormat(Path.Combine(qa,"QE190010.pdf"),17);
      File.WriteAllText(Path.Combine(qa,"layout.json"),json.Serialize(new {pages=pages,expectedPages=sections.Count+1,images=sections.Count,output=docx}));
      Console.WriteLine("Created Word report: " + sections.Count + " screenshots, " + pages + " pages.");
      if(pages!=sections.Count+1) throw new Exception("Unexpected pagination; review the rendered report before delivery.");
      return 0;
    } finally {
      try { if(doc!=null) doc.Close(false); } catch { }
      try { if(word!=null) word.Quit(false); } catch { }
      GC.Collect(); GC.WaitForPendingFinalizers();
    }
  }
}
