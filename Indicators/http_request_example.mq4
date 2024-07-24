//+------------------------------------------------------------------+
//|                                         http_request_example.mq4 |
//|                                                        Strudland |
//|                                              https://bethor.tech |
//+------------------------------------------------------------------+
#include <http_helper.mqh>

#property copyright "Strudland"
#property link      "https://bethor.tech"
#property version   "1.10"
#property indicator_chart_window

input string   API_URL="http://localhost:80/api/pairs/";
input string   API_TOKEN="API_TOKEN";
input color    button_color=clrPaleGreen;
input color    button_background=clrBlack;

#define CALL_API_BUTTON_NANME "callApiButton"

//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+
int init()
  {
   // Create a button
   CreateButton();

   return(INIT_SUCCEEDED);
  }

//+------------------------------------------------------------------+
//| OnDeinit function                                                |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
{
    // Deinitialization code
    // Clean up resources or perform other cleanup tasks
}
//+------------------------------------------------------------------+
//| ChartEvent function                                              |
//+------------------------------------------------------------------+
void OnChartEvent(const int id,
                  const long &lparam,
                  const double &dparam,
                  const string &sparam)
  {
     if(id == CHARTEVENT_OBJECT_CLICK && sparam == CALL_API_BUTTON_NANME)
     {
      // Change button state to indicate it's pressed
      ObjectSetInteger(0, CALL_API_BUTTON_NANME, OBJPROP_STATE, 1);

      CallApi();

      // Reset button state after API call
      ObjectSetInteger(0, CALL_API_BUTTON_NANME, OBJPROP_STATE, 0);
     }

  }
//+------------------------------------------------------------------+

void start()
{}

//+------------------------------------------------------------------+
//| Example API call                                                 |
//+------------------------------------------------------------------+
void CallApi()
{
   string url = API_URL;
   string headers = "Authorization: Token " + API_TOKEN + "\r\nContent-Type: application/json";
   uchar post_data[];
   string response;

   int response_code;
   bool success = HttpRequest("GET", url, headers, post_data, response, response_code);
   bool response_code_successful = IsHttpResponseSuccess(response_code);
   if (success)
   {
       Print(response);
   }
   else
   {
       Print(response);
       Print("Request failed");
   }
}

//+----------------------------------------------------------------------------------+
//| Example POST request. JSON payload is created inside CreateJSONPayload function- |
//+----------------------------------------------------------------------------------+
void SendJSONPostRequest(string url, string api_token, string json_payload)
{
    string headers = "Authorization: Token " + api_token + "\r\nContent-Type: application/json";
    uchar post_data[];
    StringToCharArray(json_payload, post_data, 0, StringLen(json_payload));

    string response;
    int response_code;
    bool success = HttpRequest("POST", url, headers, post_data, response, response_code);

    if (success)
    {
        Print("POST request successful. Response: ", response);
        // Process the response as needed
        int id = ExtractIDFromJSON(response);
        Print(id);
        SendScreenshot(url, api_token, id);
    }
    else
    {
        Print("POST request failed.");
    }
}

string ExtractIDFromJSON(string json)
{
   //JSON parsing logic

   return json;
}

//+------------------------------------------------------------------+
//| Function to prepare JSON                                         |
//+------------------------------------------------------------------+
string CreateJSONPayload(string instrument, double price, string trigger_condition)
{
    string json_payload = "{";
    json_payload += "\"instrument\": \"" + instrument + "\",";
    json_payload += "\"price\": " + DoubleToString(price, 2) + ",";
    json_payload += "\"trigger_direction\": \"" + trigger_condition + "\"";
    json_payload += "}";
    return json_payload;
}

void SendScreenshot(string url, string api_token, int alert_id) {
    // Take screenshot
    long width = 0;
    long height = 0;
    ChartGetInteger(0, CHART_WIDTH_IN_PIXELS, 0, width);
    ChartGetInteger(0, CHART_HEIGHT_IN_PIXELS, 0, height);

    // Take a screenshot of the current chart
    string screenshot_file = "screenshot.png";
    if (!ChartScreenShot(0, screenshot_file, (int)width, (int)height, ALIGN_LEFT)) {
        Print("Failed to take screenshot");
        Print("Failed screenshot error: ", GetLastError());
        // Restore original width
        return;
    }

    // Open the screenshot file
    int file_handle = FileOpen(screenshot_file, FILE_READ | FILE_BIN);
    if (file_handle == INVALID_HANDLE) {
        Print("Failed to open screenshot file: ", GetLastError());
        return;
    }

    int file_size = (int)FileSize(file_handle);
    uchar file_data[];
    ArrayResize(file_data, file_size);
    FileReadArray(file_handle, file_data, 0, file_size);
    FileClose(file_handle);

    // Prepare the POST data
    string boundary = "----WebKitFormBoundary7MA4YWxkTrZu0gW";
    string post_data = "--" + boundary + "\r\n";
    post_data += "Content-Disposition: form-data; name=\"price_alert_id\"\r\n\r\n" + alert_id + "\r\n";
    post_data += "--" + boundary + "\r\n";
    post_data += "Content-Disposition: form-data; name=\"images\"; filename=\"" + screenshot_file + "\"\r\n";
    post_data += "Content-Type: image/png\r\n\r\n";

    // Convert post_data to char array
    uchar data[];
    int res = StringToCharArray(post_data, data);
    res += ArrayCopy(data, file_data, res - 1, 0, file_size);
    string footer = "\r\n--" + boundary + "--\r\n";
    res += StringToCharArray(footer, data, res - 1);
    ArrayResize(data, res - 1);

    // Step 5: Set the headers
    string headers = "Authorization: Token " + api_token + "\r\n";
    headers += "Content-Type: multipart/form-data; boundary=" + boundary + "\r\n";

    string response;
    int response_code;
    bool success = HttpRequest("POST", url, headers, data, response, response_code);

    if (success) {
        Print("Screenshot uploaded successfully. Response: ", response);
        // Process the response as needed
    } else {
        Print("Screenshot upload failed. Error code: ", GetLastError());
    }
}

//+------------------------------------------------------------------+
//| Function to create a button                                      |
//+------------------------------------------------------------------+
void CreateButton()
{
    if (!ObjectCreate(0, CALL_API_BUTTON_NANME, OBJ_BUTTON, 0, 0, 0))
    {
        Print("Failed to create button!");
        return;
    }
    ObjectSetInteger(0, CALL_API_BUTTON_NANME, OBJPROP_CORNER, 3); // Lower right corner
    ObjectSetInteger(0, CALL_API_BUTTON_NANME, OBJPROP_XDISTANCE, 40);
    ObjectSetInteger(0, CALL_API_BUTTON_NANME, OBJPROP_YDISTANCE, 40);
    ObjectSetInteger(0, CALL_API_BUTTON_NANME, OBJPROP_XSIZE, 35); // Round button
    ObjectSetInteger(0, CALL_API_BUTTON_NANME, OBJPROP_YSIZE, 33); // Round button
    ObjectSetInteger(0, CALL_API_BUTTON_NANME, OBJPROP_COLOR, button_color);
    ObjectSetText(CALL_API_BUTTON_NANME,CharToStr(232),8,"Wingdings",button_color);
    ObjectSetString(0,CALL_API_BUTTON_NANME,OBJPROP_FONT,"Wingdings");
    ObjectSetInteger(0, CALL_API_BUTTON_NANME, OBJPROP_FONTSIZE, 20); // Increase font size for icon
    ObjectSetInteger(0, CALL_API_BUTTON_NANME, OBJPROP_BGCOLOR, button_background); // Make button raised
}

bool IsHttpResponseSuccess(int response_code)
{
    // We get 2 for ok responses (200-299), 4 (400 -> ), 5 (500 ->)
    return (response_code == 2);
}