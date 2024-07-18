//+------------------------------------------------------------------+
//|                                                  http_helper.mqh |
//|                                                        Strudland |
//|                                              https://bethor.tech |
//+------------------------------------------------------------------+
#property copyright "Strudland"
#property link      "https://bethor.tech"
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
#import

//+------------------------------------------------------------------+
//| General function for creating HTTP requests                      |
//+------------------------------------------------------------------+
bool HttpRequest(string method, string url, string headers, uchar &post_data[], string &response)
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
    
    uchar buffer[];
    int bytes_read = 0;
    int total_bytes_read = 0;
    
    do
    {
        ArrayResize(buffer, 1024);
        if (!InternetReadFile(hRequest, buffer, 1024, bytes_read))
        {
            Print("HttpRequest: Error in InternetReadFile - ", GetLastError());
            break;
        }
        
        if (bytes_read > 0)
        {
            Print(response);
            response += CharArrayToString(buffer, 0, bytes_read);
            total_bytes_read += bytes_read;
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