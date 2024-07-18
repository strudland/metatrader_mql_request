**_Note_**: A more extensive library for creating HTTP requests already exists: [MQL_REQUESTS](https://github.com/vivazzi/mql_requests) . However, I have not personally tested or verified its functionality.

# HTTP Helper for MQL4

The `http_helper.mqh` file is an include file for MQL4 that provides a custom `HttpRequest` function for making HTTP requests from within MQL4 indicators.

## Why We Need It

In MQL4, the `WebRequest` function is a convenient way to make HTTP requests and interact with web APIs. However, this function is only available in EAs and cannot be used directly in indicators. This limitation poses a challenge when developing indicators that require communication with external web services or APIs.

To overcome this limitation, the `http_helper.mqh` file provides a custom implementation of the HTTP request functionality using the `Wininet.dll` library. It allows indicators to make HTTP requests, including GET and POST requests, and retrieve the response data.

## Key Features

- Supports GET and POST requests
- Handles HTTPS requests with SSL/TLS encryption
- Allows sending custom headers and request data
- Provides error handling and timeout options
- Facilitates communication with web APIs from within indicators

## Configuration

To properly configure and use the `http_request_example` indicator, follow these steps:

1. Indicator Settings:
  - Include the `http_helper.mqh` file in your MQL4 indicator using the `#include` directive.
  - Import mqh file to your indicator. 
    - `#include <http_helper.mqh>`
  - In the "Inputs" tab, you will find the following settings:
    - `api_url`: Enter the URL of your API endpoint.
    - `api_token`: Provide the API token for authentication.
    - `button_text_color`: Set the color of the button text.
    - `button_bg_color`: Set the background color of the button.
  - Adjust these settings according to your requirements.

  ![Indicator Settings](/Images/indicator_settings.png)

2. MetaTrader 4 Options:
  - In the MetaTrader 4 platform, go to "Tools" -> "Options".
  - Navigate to the "Expert Advisors" tab.
  - Check the following options:
    - "Allow DLL imports"
    - "Allow WebRequest for listed URL"
  - In the "List of URL" field, add the following URLs:
    - For development: `http://localhost`
    - For production: `https://example-api.com`
  - Click "OK" to save the changes.

  ![Expert Advisor Options](/Images/expert_advisor_options.png)

  **Important Note**: If you are testing the indicator in a development environment, ensure that your development server is running on port 80. This is the default port used by MetaTrader 4 for web requests.

## How to Use

1. Call the `HttpRequest` function with the appropriate parameters:
  - `method`: The HTTP method (e.g., "GET", "POST")
  - `url`: The URL of the web API endpoint
  - `headers`: Additional headers to include in the request
  - `post_data`: Request data for POST requests (pass an empty array for GET requests)
  - `response`: A reference to a string variable to store the response data
2. Check the return value of the `HttpRequest` function to determine the success or failure of the request.
3. Process the response data as needed in your indicator.


## Examples

Please note that the usage examples for the `HttpRequest` function can be found in the `Indicators/http_request_example.mq4` file.

If you load the `http_request_example` indicator in the MetaTrader 4 platform, a button will appear in the bottom right corner of the chart. Clicking this button will trigger an API call using the `HttpRequest` function.

Additionally, the `http_request_example.mq4` file includes two example functions: `SendScreenshot` and `SendJSONPostRequest`. These functions demonstrate how to send POST requests with image uploads and JSON payloads, respectively. However, these functions are not actively called within the example indicator and are provided as a reference for users who may need to implement similar functionality in their own projects.

