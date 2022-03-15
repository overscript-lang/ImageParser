#app ImageParser, Version="1.0.0"

const bool ImgAltByH = true;
const int PageImgLimit = 0, SiteImgLimit = 0, LinkLimit = 0;
const int NestingLimit = 1000000, MaxСontentLength = 300000;
const string ResultsEncoding = "utf-8";

string ImgTagAttr, HttpHeaders, ResultsFile, IndexPage, SiteHost, SiteArg, FileArg;

int StartImageCount;
string[] Args = StartArgs();

if(Length(Args) >= 2) {
	SiteArg = Args[0];
	FileArg = Args[1];
}else{
	SiteArg = ReadLine("Enter site (domain): ");
	FileArg = ReadLine("Enter the file to save to:");
}
WriteLine($"Site: {SiteArg}; File: {FileArg}"); 

StrList Images = new StrList();
StrList Links = new StrList();
IntList Nesting = new IntList();

ImgTagAttr = "";
ResultsFile = FileArg;
StartParse($"http://{SiteArg}/");
WriteLine();
ReadKey("Press any key to exit.");


string GetHost(string url){
	string host = url.ToLower();
	if(host.StartsWith("http://")) host = host.Substring(7); 
	else if(host.StartsWith("https://")) host = host.Substring(8);
	
	if(host.StartsWith("www.")) host = host.Substring(4);
	int i = host.IndexOf('/');
	if(i >= 0) host = host.Left(i);
	return host;
}


LoadImages(string path){
	Images.Clear();

	if (!FileExists(path)) return;
	string text = ReadAllText(path, ResultsEncoding);
	while(text.EndsWith("\r\n")) text = text[.. -2];
	string[] arr=text.Split("\r\n");
	int i, l=arr.Length();
	string s;
	for(int n = 0; n < l; n++){
		s=arr[n];
		i = s.IndexOf('\t');
		if(i >= 0) arr[n] = s.Left(i);
	}
	Images.AddRange(arr);
	
	StartImageCount = Images.Count;
}

string LoadPage(string url){
	try{
		string data = Fetch(url);
	}catch{
		WriteLine($"Failed to open {url} ({exMessage})");
		return;
	}
	int i = data.IndexOf("\r\n\r\n");
	if(i >= 0){ 
		data = data.Substring(i + 4);
		data = data.Replace("\r", "");
		data = data.Replace('\n', ' ');
	}
	return data;
}

StartParse(string urlToParse){
	WriteLine("Starting...");
	IndexPage = urlToParse;

	LoadImages(ResultsFile);
	if(StartImageCount > 0) WriteLine($"Previously found images: {StartImageCount}.");
	Links.Clear();

	int curLink = 0;
	string linkUrl = "";
	
	WriteLine("Home page parsing...");
	string r, article;
	SiteHost = GetHost(IndexPage);
	r = LoadPage(IndexPage);
	if(r == null) return;
	ParseLinks(r, IndexPage, 1);
	
	if(Links.Count > 0){

		do{

			linkUrl = Links[curLink];
			WriteLine("Parsing " + (curLink + 1) + "/" + Links.Count + "... New images: " + (Images.Count - StartImageCount) + ". Page: " + Shorten(linkUrl));

			r = LoadPage(linkUrl);

			if(r.Length() > MaxСontentLength) r = "";
			if(Links.Count < LinkLimit || LinkLimit == 0){
				if(Nesting[curLink] <= NestingLimit) ParseLinks(r, linkUrl, Nesting[curLink] + 1);
			}

			string foundImages = GetArticleImages(r, linkUrl);

			if(foundImages.Length() > 0){
				AppendAllText(ResultsFile, foundImages, ResultsEncoding);
				if(SiteImgLimit > 0 && Images.Count >= SiteImgLimit) break;
			}
			
			curLink++;
		}while(curLink < Links.Count);
	}
	WriteLine(curLink + "/" + Links.Count + " - Completed. Images (new/total): " + (Images.Count - StartImageCount) + "/" + Images.Count + ".");
}

static string[] FileExtensions = new string[]{".png", ".gif", ".jpeg", ".jpg", ".pdf", ".zip", ".doc", ".gzip", ".rar", ".xml", ".rss"};

bool IsNotPage(string href){
	string ext = GetExtension(href);
	if(FileExtensions.IndexOf(ext) >= 0) return true;

	if(href.IndexOf("javascript:", true) >= 0) return true;
	if(href.IndexOf('#') >= 0 ) return true;
	if(href.IndexOf("rss", true) >= 0) return true;
	if(href.IndexOf("mailto:", true) >= 0) return true;
	if(href.IndexOf("ftp://", true) >= 0) return true;
	if(href == IndexPage || href + "/" == IndexPage) return true;
	return false;
}

ParseLinks(string text, string url, int uv){
	int i, i2, g;
	string href,b;
	int urlNum = Links.IndexOf(url);

	string bh = GetBaseHref(text);
	if(bh.Length() > 0){ 
		if(bh.IndexOf("://") < 0) bh = GetAbsoluteUri(url, bh);
		url = bh;
	}

	i = text.IndexOf("<a ", true);
	
	while (i >= 0){
		i2 = text.IndexOf('>', i + 3);
		if(i2 < 0) break;

		b = text[i..i2 + 1];
		href = GetTagParam(b, "href");
		
		if(href.StartsWith("//")) href = "http:" + href;

		string hrefHost = GetHost(href);
	
		if(!href.StartsWith("http", true) || hrefHost == SiteHost ){
			if(!IsNotPage(href)){
		
				href = GetAbsoluteUri(url, href);
				
				if(Links.IndexOf(href) < 0 && GetHost(href) == SiteHost){
					
						if(LinkLimit > 0 && Links.Count >= LinkLimit) break;
			
						Links.Add(href);
						Nesting.Add(uv);
					
				}

			}
		}
		i = text.IndexOf("<a ", i + 3, true);
	}

}

string GetBaseHref(string text){
	string url = "", b;
	int i,i2;
	i = text.IndexOf("<base", true);
	if( i >= 0){
		i2 = text.IndexOf('>', i + 6);
		b = text[i..i2 + 1];
		url = GetTagParam(b, "href");
	}
	return url;
}

string GetArticleImages(string text, string url){
	string res = "";
	int g, g2, g0, g3, g4;
	string h1 = "";
	string[] hh = new string[5];
	string url0 = url;

	string b, img, alt, src, href;
	int i, i2, i3, i4, i5;
	int kk = 0;

	string bh = GetBaseHref(text);
	if(bh.Length() > 0) url = GetAbsoluteUri(url, bh);
	
	i = text.IndexOf("<img", true);
	while(i >= 0){
		i2 = text.IndexOf(">", i + 5, true);
		if (i2 < 0) break;
		img = text[i..i2 + 1];
		i3 = img.IndexOf(ImgTagAttr);
		if (i3 >= 0){
			src = GetTagParam(img, "src");
			alt = GetTagParam(img, "alt");

			if(alt.Length() == 0 || ImgAltByH){
				g = i;

				hh[1] = hh[2] = hh[3] = hh[4] = "";
				for(int n = 1; n <= 4; n++){
					g2 = text.LastIndexOf("<h" + n, g, true);
					if(g2 >= 0){
						g2 = text.IndexOf(">", g2);
						g3 = text.IndexOf("</h" + n, g2, true);
						if (g3 >= 0) hh[n] = text[g2 + 1..g3];

					}
					if (hh[n].Length() > 0){ h1 = StripTags(hh[n]) ; break;}
				}

				alt = h1;

			}

			if(src.Length() > 0){
				alt = ClearStr(alt);
				alt = typeof("System.Net.WebUtility")->HtmlDecode(alt);
				src = ClearStr(src);

				href = GetAbsoluteUri(url, src);
			
				if (Images.IndexOf(href) < 0){
			
					res += $"{href}\t{url0}\t{alt}\r\n";
					Images.Add(href);
					kk++;

					if(PageImgLimit > 0 && kk >= PageImgLimit) break;
				}
			}
		}

		i = text.IndexOf("<img", i2, true);
	}

	return res;
}

string ClearStr(string t){
	t = t.Replace("\r", "");
	t = t.Replace("\n", "");
	t = t.Replace("\t", "");
	if (t.Length() > 0) t = t.RegexReplace("<.*?>", "");

	return t;
}


string GetTagParam(string t, string p){
	string res = "", quote, prm = p + "=";
	int i, i2, i3, i4, l = prm.Length();
	
	i = t.IndexOf(prm, true);
	if(i >= 0){
		quote = t.Substring(i + l, 1);
		if(quote != "'" && quote != "\"" ){
			i3 = t.IndexOf(" ", i + l);
			i4 = t.IndexOf(">", i + l);
			if(i4 >= 0 && i3 >= 0 && i4 < i3){
				i3 = i4;
			}else{
				if(i3 < 0) i3 = i4;
			}
			l--;
			
		}else{
			i3 = t.IndexOf(quote, i + l + 1);
		}
		
		if(i3 < 0) i3 = Length(t) + 1;
		res = t[i + l + 1..i3].Trim();
		res = res.Replace("\"", "");
		res = res.Replace("'", "");
		if(quote != "'" && quote != "\"" && res.EndsWith("/")) res = res[.. -1];

	}
	return res;
}

string StripTags(string html){
	if(html.Length() > 0) return html.RegexReplace("<.*?>", "");
}

string Shorten(string t){
	if(t.Length() > 70) t = t.Left(50) + "...";
	
	return t;
}


class StrList{
	int Capacity;
	public int Count;
	string[] Items;
	
	New(){
		Clear();
	}
	public Add(string v){
		if(Count >= Capacity - 1){Capacity *= 2; Resize(Items, Capacity);}
		Items[Count] = v;
		Count++;
		
	}
	public Clear(){
		Capacity = 10; 
		Count = 0;
		Items = new string[Capacity];
	}
	public Remove(int index){
		int c = Count - 1;
		for(int i = index; i < c; i++) Items[i] = Items[i + 1];
		Count = c;
	}
	public AddRange(string[] values){
		Items.InsertRange(Count, values);
		Count += values.Length();
		Capacity = Items.Length();
		
	}
	public int IndexOf(string value){
		return Items.IndexOf(value);
	}
	public string GetItem(int index){ 
		return Items[index];
	}
	public SetItem(int index, string value){ 
		Items[index] = value;
	}
	
}

class IntList{
	int Capacity;
	public int Count;
	int[] Items;

	New(){
		Clear();
	}
	public Add(int v){
		if(Count >= Capacity - 1){
			Capacity *= 2; 
			Resize(Items, Capacity);
		}
		Items[Count] = v;
		Count++;
		
	}
	public Clear(){
		Capacity = 10; 
		Count = 0; 
		Items = new int[Capacity];
	}
	public Remove(int index){
		int c = Count - 1;
		for(int i = index; i < c; i++) Items[i] = Items[i + 1];
		Count = c;
	}
	public int GetItem(int index){ 
		return Items[index];
	}
	public SetItem(int index, int value){ 
		Items[index] = value;
	}
	
}
