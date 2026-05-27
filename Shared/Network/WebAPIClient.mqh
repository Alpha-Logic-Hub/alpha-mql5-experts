//+------------------------------------------------------------------+
//| WebAPIClient.mqh                                                  |
//| Alpha Logic Hub — Conector de APIs Externas (JSON / MCP)         |
//+------------------------------------------------------------------+

//+------------------------------------------------------------------+
//| WebGet — GET request con timeout                                 |
//+------------------------------------------------------------------+
string WebGet(string url, int timeoutMs = 5000)
{
   char data[], result[];
   string headers = "Content-Type: application/json\r\n";
   int res = WebRequest("GET", url, headers, timeoutMs, data, result, headers);

   if(res != 200) {
      Print("[WebAPI] GET FAILED — HTTP ", res, " | URL: ", url);
      return "";
   }

   return CharArrayToString(result);
}

//+------------------------------------------------------------------+
//| WebPost — POST request con body JSON                             |
//+------------------------------------------------------------------+
string WebPost(string url, string jsonBody, int timeoutMs = 5000)
{
   char data[];
   StringToCharArray(jsonBody, data, 0, StringLen(jsonBody));

   char result[];
   string headers = "Content-Type: application/json\r\n";
   int res = WebRequest("POST", url, headers, timeoutMs, data, result, headers);

   if(res != 200 && res != 201) {
      Print("[WebAPI] POST FAILED — HTTP ", res, " | URL: ", url);
      return "";
   }

   return CharArrayToString(result);
}
