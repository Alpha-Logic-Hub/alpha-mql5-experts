//+------------------------------------------------------------------+
//| TelegramBot.mqh                                                   |
//| Alpha Logic Hub — Alertas del Hub vía Telegram Bot API           |
//+------------------------------------------------------------------+

string g_telegramToken = "";   // Set via input or init
string g_telegramChatId = "";  // Set via input or init

//+------------------------------------------------------------------+
//| InitTelegram — configurar token y chat ID                        |
//+------------------------------------------------------------------+
void InitTelegram(string token, string chatId)
{
   g_telegramToken = token;
   g_telegramChatId = chatId;
   Print("[TelegramBot] Initialized — ChatID=", chatId);
}

//+------------------------------------------------------------------+
//| SendTelegramAlert — enviar mensaje simple                        |
//| Requiere WebAPIClient.mqh para la llamada HTTP                   |
//+------------------------------------------------------------------+
void SendTelegramAlert(string message)
{
   if(g_telegramToken == "" || g_telegramChatId == "") {
      Print("[TelegramBot] Not configured — skipping alert: ", message);
      return;
   }

   // WebRequest call (MetaTrader requires AllowWebRequest in Tools > Options)
   string url = "https://api.telegram.org/bot" + g_telegramToken +
                "/sendMessage?chat_id=" + g_telegramChatId +
                "&text=" + message;

   char data[], result[];
   string headers = "Content-Type: application/x-www-form-urlencoded\r\n";
   int res = WebRequest("POST", url, headers, 5000, data, result, headers);

   if(res != 200) {
      Print("[TelegramBot] Alert FAILED — HTTP ", res, " | Message: ", message);
   } else {
      Print("[TelegramBot] Alert SENT: ", message);
   }
}
