# ImageParser

This app is written in OverScript.
The script finds all images on the specified site and saves them to a file as a list:\
`src	page_url	alt`
(separator is tab)

if the image does not have alt, then the header above the image will be used as the alt. To prevent this, you need to set:
`const bool ImgAltByH = false;`

There are also the following constants:

```
const int PageImgLimit = 0, SiteImgLimit = 0, LinkLimit = 0;
const int NestingLimit = 1000000, MaxСontentLength = 300000;
const string ResultsEncoding = "utf-8";
```

*PageImgLimit* - how many maximum images to take from the page;\
*SiteImgLimit* - how many maximum images to take from the site;\
*LinkLimit* - how many maximum pages to crawl;\
*NestingLimit* - maximum allowable page nesting;\
*MaxСontentLength* - maximum allowed page code length;\
*ResultsEncoding* - result file encoding.
