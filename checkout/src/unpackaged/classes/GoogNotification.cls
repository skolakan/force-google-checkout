public class GoogNotification {
	
	/* build the two types of request that the API understands 
	
	A notification-data-token-request 
	requests a token that can subsequently be used to retrieve notifications via the Polling
API. This request specifies the most recent time that can be associated with the notifications that the Polling API will
return in any notification-data-response stemming from the initial token request.
To submit a notification-data-token-request send an HTTP request that uses HTTP Basic Authentication to one of the
following URLs:
Sandbox environment:
https://sandbox.google.com/checkout/api/checkout/v2/reports/Merchant/MERCHANT_ID
Production environment:
https://checkout.google.com/api/checkout/v2/reports/Merchant/MERCHANT_ID
The following XML shows a sample notification-data-token-request.
The <start-time> tag indicates that the application will
be receiving any notifications submitted after December 12, 2007 at 2 p.m. UTC.

<notification-data-token-request xmlns="http://checkout.google.com/schema/2">
<start-time>2007-12-10T14:00:00</start-time>
</notification-data-token-request>


	A notification-data-request 
	requests a list of notifications from the Polling API server. The continue-token specified in the
request identifies the set of notifications that should be included in the notification-data-response.
To submit a notification-data-request send an HTTP request that uses HTTP Basic Authentication to the following URL as
with a notification-data-token-request:
Sandbox environment:
https://sandbox.google.com/checkout/api/checkout/v2/reports/Merchant/MERCHANT_ID
Production environment:
https://checkout.google.com/api/checkout/v2/reports/Merchant/MERCHANT_ID
The following XML shows a sample notification-data-request:
<notification-data-request xmlns="http://checkout.google.com/schema/2">
<continue-token>CPeFhvuBIxDxwp6Jn4w6GAI</continue-token>
</notification-data-request>
	
	*/
	private static string hdr= '<?xml version="1.0" encoding="UTF-8"?>' ;
	static integer debug = 2; 

	public static string tokenRequest ( datetime sincewhen) { 
		xmldom.element token =new xmldom.element('notification-data-token-request'); 
		token.attributes.put('xmlns','http://checkout.google.com/schema/2');
		xmldom.element st = new xmldom.element('start-time');
		st.nodeValue = getTDate(sincewhen );
		token.appendChild(st);
		string ret = hdr +  token.toXmlString();
		if(debug>1) system.debug(ret);
		return ret;
	} 
	
	public static string dataRequest(string c_token) {
		xmldom.element token =new xmldom.element('notification-data-request'); 
		token.attributes.put('xmlns','http://checkout.google.com/schema/2');
		xmldom.element st = new xmldom.element('continue-token');
		st.nodeValue = c_token;
		token.appendChild(st);
		string ret = hdr +  token.toXmlString();
		if(debug>1) system.debug(ret);
		return ret;	
	}
	static string getTDate(datetime dt) { 
		return string.valueofgmt(dt).replace(' ','T');	  
	}
	 
}