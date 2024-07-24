//+------------------------------------------------------------------+
//|                                                  http_helper.mqh |
//|                                                        Strudland |
//|                                   https://precisionintrading.com |
//+------------------------------------------------------------------+
#property copyright "Strudland"
#property link      "https://precisionintrading.com"
#property version "1.0"
#property strict

#import "Wininet.dll"
int InternetOpenW(string sAgent, int lAccessType, string sProxyName, string sProxyBypass, int lFlags);
int InternetConnectW(int hInternet, string sServerName, int nServerPort, string sUsername, string sPassword, int lService, int lFlags, int lContext);
int HttpOpenRequestW(int hConnect, string sVerb, string sObjectName, string sVersion, string sReferer, string sAcceptTypes, int lFlags, int lContext);
int HttpSendRequestW(int hRequest, string sHeaders, int lHeadersLength, uchar& sOptional[], int lOptionalLength);
int InternetReadFile(int hFile, uchar& sBuffer[], int lNumBytesToRead, int& lNumberOfBytesRead);
int InternetCloseHandle(int hInet);
int InternetSetOptionW(int hInternet, int dwOption, int& lpBuffer, int dwBufferLength);
bool HttpQueryInfoW(int hRequest, int dwInfoLevel, uchar& lpBuffer[], int& lpdwBufferLength, int& lpdwIndex);
#import

#define MAX_RESPONSE_SIZE 1048576

//+------------------------------------------------------------------+
//| General function for creating HTTP requests                      |
//+------------------------------------------------------------------+
bool HttpRequest(string method, string url, string headers, uchar &post_data[], string &response, int &response_code)
{
    bool success = false;
    int hInternet = InternetOpenW("MyAgent", 0, NULL, NULL, 0);
    if (hInternet == 0)
    {
        Print("HttpRequest: Error in InternetOpenW - ", GetLastError());
        return false;
    }
    
    // Set timeout options
    int timeout = 5000; // 5 seconds
    InternetSetOptionW(hInternet, 6, timeout, 4); // INTERNET_OPTION_RECEIVE_TIMEOUT
    InternetSetOptionW(hInternet, 7, timeout, 4); // INTERNET_OPTION_SEND_TIMEOUT
    InternetSetOptionW(hInternet, 8, timeout, 4); // INTERNET_OPTION_CONNECT_TIMEOUT
    
    string server = "";
    int port = 0;
    bool isHttps = false;
    
    // Extract server name, port, and scheme from the URL
    int pos = StringFind(url, "://");
    if (pos > 0)
    {
        string scheme = StringSubstr(url, 0, pos);
        isHttps = (StringCompare(scheme, "https", false) == 0);
        
        url = StringSubstr(url, pos + 3);
        pos = StringFind(url, "/");
        if (pos > 0)
        {
            server = StringSubstr(url, 0, pos);
            url = StringSubstr(url, pos);
        }
        else
        {
            server = url;
            url = "/";
        }
        
        pos = StringFind(server, ":");
        if (pos > 0)
        {
            port = (int)StringToInteger(StringSubstr(server, pos + 1));
            server = StringSubstr(server, 0, pos);
        }
        else
        {
            port = isHttps ? 443 : 80;
        }
    }
    
    int hConnect;
    int hRequest;
    if (isHttps)
    {
        hConnect = InternetConnectW(hInternet, server, port, "", "", 3, 0, 0);
        Print(hConnect);
        if (hConnect == 0)
        {
            Print("HttpRequest: Error in InternetConnectW - ", GetLastError());
            InternetCloseHandle(hInternet);
            return false;
        }
        
        int flags = 0x00800000; // INTERNET_FLAG_SECURE
        hRequest = HttpOpenRequestW(hConnect, method, url, NULL, NULL, NULL, flags, 0);
        Print(hRequest);
        if (hRequest == 0)
        {
            Print("HttpRequest: Error in HttpOpenRequestW - ", GetLastError());
            InternetCloseHandle(hConnect);
            InternetCloseHandle(hInternet);
            return false;
        }
    }
    else
    {
        hConnect = InternetConnectW(hInternet, server, port, "", "", 3, 0, 0);
        if (hConnect == 0)
        {
            Print("HttpRequest: Error in InternetConnectW - ", GetLastError());
            InternetCloseHandle(hInternet);
            return false;
        }
        
        hRequest = HttpOpenRequestW(hConnect, method, url, NULL, NULL, NULL, 0, 0);
        if (hRequest == 0)
        {
            Print("HttpRequest: Error in HttpOpenRequestW - ", GetLastError());
            InternetCloseHandle(hConnect);
            InternetCloseHandle(hInternet);
            return false;
        }
    }
    
    int post_data_size = ArraySize(post_data);
    if (!HttpSendRequestW(hRequest, headers, StringLen(headers), post_data, post_data_size))
    {
        Print("HttpRequest: Error in HttpSendRequestW - ", GetLastError());
        InternetCloseHandle(hRequest);
        InternetCloseHandle(hConnect);
        InternetCloseHandle(hInternet);
        return false;
    }
    
   // Check the response code
   uchar status_buffer[64];
   int buffer_length = ArraySize(status_buffer);
   int index = 0;
   if (!HttpQueryInfoW(hRequest, 19, status_buffer, buffer_length, index)) // 19 is HTTP_QUERY_STATUS_CODE
   {
       Print("HttpRequest: Error in HttpQueryInfoW - ", GetLastError());
       InternetCloseHandle(hRequest);
       InternetCloseHandle(hConnect);
       InternetCloseHandle(hInternet);
       return false;
   }
   
    response_code = (int)StringToInteger(CharArrayToString(status_buffer, 0, buffer_length));
    uchar buffer[];
    int bytes_read = 0;
    int total_bytes_read = 0;
    
    do
    {
       ArrayResize(buffer, 1024);
       if (!InternetReadFile(hRequest, buffer, 1024, bytes_read))
       {
           Print("HttpRequest: Error in InternetReadFile - ", GetLastError());
           response = "HttpRequest: Error in InternetReadFile - " + GetLastError();
           break;
       }
       
       if (bytes_read > 0)
       {
           response += CharArrayToString(buffer, 0, bytes_read);
           total_bytes_read += bytes_read;
           
           // Check if response starts with DOCTYPE (indicating an error)
           if (StringSubstr(response, 0, 9) == "<!DOCTYPE")
           {
               Print("Received an HTML error response");
               break;
           }
           
           // Break if response size exceeds the maximum
           if (total_bytes_read > MAX_RESPONSE_SIZE)
           {
               Print("Response exceeds maximum size limit");
               break;
           }
       }
    }
    while (bytes_read > 0);
    
    if (total_bytes_read > 0)
    {
        success = true;
    }
    
    InternetCloseHandle(hRequest);
    InternetCloseHandle(hConnect);
    InternetCloseHandle(hInternet);
    
    return success;
}
