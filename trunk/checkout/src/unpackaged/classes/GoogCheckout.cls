/*
Copyright (c) 2008 salesforce.com, inc.
All rights reserved.

Redistribution and use in source and binary forms, with or without
modification, are permitted provided that the following conditions
are met:

1. Redistributions of source code must retain the above copyright
   notice, this list of conditions and the following disclaimer.
2. Redistributions in binary form must reproduce the above copyright
   notice, this list of conditions and the following disclaimer in the
   documentation and/or other materials provided with the distribution.
3. The name of the author may not be used to endorse or promote products
   derived from this software without specific prior written permission.

THIS SOFTWARE IS PROVIDED BY THE AUTHOR "AS IS" AND ANY EXPRESS OR
IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES
OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED.
IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR ANY DIRECT, INDIRECT, 
INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT
NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY
THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
(INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF
THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
*/
public class GoogCheckout {
 
	Google_Merchant__c  merchantInfo;  
	final string sandbox = 'https://sandbox.google.com/checkout/api/checkout/v2';
	final string checkout = 'https://checkout.google.com/api/checkout/v2';
	public integer debug = 1; 
  	datetime endDate;  
  	public  useragent ua; 
  	opportunity[] opps;
	set<string> gnums = new set<string>();
  	
  	XmlDom.Element[] olist = new XmlDom.Element[]{};
  	XmlDom.Element[] change = new XmlDom.Element[]{};
	
	// constructor, id and key must be in the org, currently assume just one merchant account exists	
	public googCheckout() { 
		this.merchantInfo = [ Select g.SystemModstamp, g.OwnerId, g.Name, g.Merchant_Key__c, g.Merchant_ID__c, g.ContinueToken__c,
			g.Merchant_Email__c, g.has_more__c, g.LastModifiedDate, g.Use_Sandbox__c, g.IsDeleted, g.Id, g.Last_Update_Run__c,
			g.CreatedDate, g.CreatedById From Google_Merchant__c g limit 1];
		
		system.assert( merchantInfo!=null , 'missing merchant ID and Key record');
 		
		ua = new useragent(EncodingUtil.base64Encode( blob.valueof( 
			this.merchantInfo.Merchant_ID__c + ':' + this.merchantInfo.Merchant_Key__c ))); 
	}

	public string getMerchant_ID() { return merchantInfo.Merchant_ID__c; }
	public string getMerchant_Key() { return merchantInfo.Merchant_Key__c; }
	public void setLastRun(datetime sd ) { merchantInfo.Last_Update_Run__c = sd; }
	
	public void setContinueToken(datetime sincewhen) { 
		// perform a query to set it, provide a start date
		ua.post( getReportsEndpoint() , GoogNotification.tokenRequest(sincewhen) );	
		xmldom ret = ua.getResponseDom(); 
		ret.dumpAll();
		// save the token into the merchantInfo 
		string tok = ret.ownerDocument().getValue('continue-token');
		this.merchantInfo.ContinueToken__c = tok;
		this.merchantInfo.has_more__c = true; // by definition we have not begun yet
	} 
	public void setContinueTokenUpdate(datetime sincewhen) { 
		setContinueToken(sincewhen);
		update this.merchantInfo;
	}
	public void getOneBatch() {  // performs one callout
		system.assert( this.merchantInfo.ContinueToken__c!= null , 'missing continue token' );
		
		ua.post( getReportsEndpoint() , 
			GoogNotification.dataRequest(this.merchantInfo.ContinueToken__c ) );
		xmldom ret = ua.getResponseDom(); 
		
		if (debug > 2) {
			ret.dumpAll();
			/*		for (xmldom.element e : ret.getElementsByTagName('new-order-notification') ) {			
				string gon = e.getValue('google-order-number');
				system.debug( gon );
				gnums.add(gon ); 
			}
			*/
		}
		
		olist.addAll( ret.root.getElementsByTagName('new-order-notification') );
  		change.addAll( ret.root.getElementsByTagName('order-state-change-notification') );		

		this.merchantInfo.has_more__c = ret.ownerDocument().getValue('has-more-notifications') == 'true';				
		this.merchantInfo.ContinueToken__c = ret.ownerDocument().getValue('continue-token');
		if (debug > 2) { system.debug(merchantInfo); }
	}
	
	public void getAllBatches() {  // loop until we cannot callout again
		system.debug(this.merchantInfo);
		gnums.clear();
		olist.clear(); 
		change.clear(); 
		
		while (this.merchantInfo.has_more__c && Limits.getCallouts() < Limits.getLimitCallouts() ) 
		{ 
			system.debug('number of callouts '+ Limits.getCallouts() +' ' + limits.getlimitcallouts() ); 
			getOneBatch(); 
		} 
		merchantInfo.last_update_run__c = system.now();// cant use now, since there is a 1 hour latency
		// done with callouts, begin writing into database 
		update merchantInfo; 
		if (debug > 2) { system.debug(merchantInfo); }

		processNotificationOrderList();
	}
	


  	/* 
  	 * this is the main routine to create objects inside force.com
  	 * creates contacts, opportunities, opp contact roles and 
  	 * does not set contact campaign membership at this time (campaignmemberstatus)
  	 */
  	public void processNotificationOrderList (  ) { 
  		// create the opportunities if any are missing
		//limit_near('aa');
		// trick is to find the missing ones, avoid creating and populating all 
		// or we hit 
		// System.Exception: Too many script statements: 200001
		// can only do 35 before hitting this limit
		// the xmldom getValue() is inefficent in statements executed 
		// olist and change have the notifications here 
		for(XmlDom.Element o: olist ) { gnums.add(o.getValue('google-order-number')); }
		for(XmlDom.Element o: change ) { gnums.add(o.getValue('google-order-number')); }
		system.debug( 'processNotificationOrderList responses:' +gnums.size()); 
		
		opps = [select id,Google_Order_Number__c ,Unit_Price__c,Item_Name__c from opportunity 
			where Google_Order_Number__c in :gnums ];
		
		map<string,opportunity> orderNumMap = new map<string,opportunity> {};
		for(opportunity o:opps) { orderNumMap.put(o.Google_Order_Number__c,o); }
		system.debug( 'processNotificationOrderList orderNumMap:' +orderNumMap.keyset().size()); 
		
		for(XmlDom.Element o: olist ) { 
			if (debug > 1) { o.dumpAll(); }
			opportunity opp ;
			if ( orderNumMap.containsKey( o.getValue('google-order-number') ) ) {
				opp = orderNumMap.get( o.getValue('google-order-number'));
			}
			else { opp = new Opportunity( ); }
			
			if ( opp.Item_Name__c == null ) {
				element_to_opp(o,opp);			 // expensive, about 2544 statements
//				limit_near('to opp' + opps.size());
			}
			
			if ( opp.Id == null ) 
				opps.add( opp );	
		}
	/*	for (opportunity o:opps) {system.debug(o);}		upsert opps google_order_number__c;		*/
		
		system.debug('createOpportunities '+opps.size());
		//limit_near('create opps');	

		if ( opps.size() < 1) { 
			//merchantInfo.Last_Update_Run__c  = latestNotice(olist,change);
			//update merchantInfo;
			return; }
		 	
	 	/* processOrderStateChanges, set the state changes into the opps
	 	 * sort thru the order-state-change
	 	 * NOTE: we assume these are in the order that the timestamps would specify
	 	 * TODO sort by timestamp to be sure
	 	 */
	 	for (XmlDom.Element o :change) {  
			//if ( o.nodeName == 'order-state-change-notification' ) {
				// match this notice to one opp from the opp list
				opportunity opp = orderNumMap.get(o.getValue('google-order-number'));
				if (opp == null) continue; 
				if (debug > 4) { o.dumpAll(); } 
				
				// apply the state changes, sometimes an order state 
				// does not change, in this case discard that info
				string new_fu_state = o.getValue('new-fulfillment-order-state');
				string pre_fu_state = o.getValue('previous-fulfillment-order-state');
				string new_fi_state = o.getValue('new-financial-order-state');
				string pre_fi_state = o.getValue('previous-financial-order-state');
				if ( new_fu_state != pre_fu_state )
					opp.fulfillment_order_state__c = new_fu_state;
				else if ( new_fi_state != pre_fi_state )
					opp.financial_order_state__c = new_fi_state;			
			//}
	 	}
		//limit_near('processOrderStateChanges');	
		
		upsert opps google_order_number__c;		// begin to update records
	
		// create contacts and opportunity roles as needed
		list<string> cons =new list<string>{}; 
		for(XmlDom.Element ele: olist ) { 
			//if (ele.nodeName != 'new-order-notification' ) continue; 
			if (ele.getValue('buyer-id') != null ) {
				cons.add( ele.getValue('buyer-id') ); 
			}
		}
		
		// map the contacts by google buyer number
		Map<string, Contact> buyerMap = new Map<string, Contact>{};
		for (Contact cc:[Select id, email,google_buyer_id__c 
							From Contact where Google_Buyer_id__c in :cons]) 
		{
			buyerMap.put(cc.Google_Buyer_id__c,cc);
		}
		
		// create missing contacts, add to map, need a default account
		Account acc = [ select id from account where name = 'Individual' limit 1];
		system.assert(acc!=null,'missing Individual account used for new contacts');
		
		/* handle duplicates, found the existing contact by 
		 * google buyer ID. 
		 * otherwise we create a new contact using buyer info
		 * if buyer selects email private, we get this 
		 * bob-b762g0gvb5l@xlocal.google.com 
		 * which prevents us from emailing the buyer directly.
		 */
		for(XmlDom.Element ele: olist ) { 
			//if (ele.nodeName != 'new-order-notification' ) continue; 
			if ( ! buyerMap.containsKey( ele.getValue('buyer-id') )  )  {
				contact c =  getContact(ele);
				c.accountid = acc.id;
				buyerMap.put( ele.getValue('buyer-id'), c );
			}
			// we could enrich the contact if it exists, 
		}

		if (debug>5) system.debug('buyer (contact) map '+buyerMap);			
		upsert buyerMap.values() Google_Buyer_id__c;
		//limit_near('upsert buyerMap');		
	
		// createMissingOppRoles		
		Map<id, Contact> cidMap = new Map<id, Contact>(buyerMap.values());
		map<id, opportunity> om = new map<id,opportunity>(opps);
		List<OpportunityContactRole> ocrm = new List<OpportunityContactRole>([
			Select id, OpportunityId, ContactId From OpportunityContactRole 
			where contactid in :cidMap.keySet() 
			and opportunityId in :om.keySet()]);
		
		for (id cid: cidMap.keySet() ) { 
			for (id oid: om.keySet() ) { 
				if ( ! findMatchingRole( ocrm , cid, oid ) )
					// add a role if we can't find one
					ocrm.add( new OpportunityContactRole(
						opportunityid = oid, 
						contactid = cid,
						role = 'Donor' ));
			}
		}
		if (debug>2) system.debug(ocrm);
		upsert ocrm;		// write the new roles 


		// update the last run date with the date from the most 
		merchantInfo.Last_Update_Run__c  = latestNotice(olist,change);
		update merchantInfo;
		system.debug( merchantInfo );
	}
	
	// or endDate if there are no notices
	datetime latestNotice( XmlDom.Element[] olist,XmlDom.Element[] change ) { 
		//system.debug( merchantInfo.Last_Update_Run__c );		
		string a, b;
		datetime bb, ret = endDate; 
		if ( olist.size() > 0 ) { 
			a = olist[ olist.size()-1 ].getValue('timestamp').replace('T', ' '); 
			ret =  Datetime.valueOfGmt( a );
		}
		if (change.size()> 0 ) {
			b = change[ change.size()-1 ].getValue('timestamp').replace('T', ' '); 
		 	bb = 	Datetime.valueOfGmt( b );
		}	
		
		if ( bb > ret  ) 	ret = bb;
		system.debug ( a + ' '+b + ' ' + ret);
		return ret;
	}
	
	boolean findMatchingRole( List<OpportunityContactRole> ocrm, id cid, id oid) {
		boolean ret = false; 
		for ( 	OpportunityContactRole r:ocrm) {
			if ( r.opportunityid == oid && r.contactid == cid) 
				ret = true;
		} 
		return ret;
	}
	

	// map a DOM element to a new opportunity 
	public void element_to_opp(XmlDom.Element o,Opportunity opp) {
		opp.google_order_number__c = o.getValue('google-order-number');
		//getOrderNumber();
		opp.name = o.getValue('item-name');
		
		string close_time = o.getValue('timestamp');

		close_time = close_time.replace('T', ' ');
		datetime cd = Datetime.valueOfGmt(close_time) ;
		opp.closedate = Date.valueOf(close_time);
		
		opp.stagename = 'Closed';
		opp.amount = Double.valueOf( o.getValue('order-total') );
		opp.item_name__c = o.getValue('item-name');
		opp.item_description__c = o.getValue('item-description');
		opp.order_creation_date__c = 
			Datetime.valueOfGmt( o.getValue('timestamp').replace('T', ' ') );
			
		opp.fulfillment_order_state__c = o.getValue('fulfillment-order-state');
		opp.financial_order_state__c = o.getValue('financial-order-state');
		opp.PAYment_type__c = 'Google Checkout';
		opp.quantity__c = Double.valueOf( o.getValue('quantity') );
		opp.unit_price__c = Double.valueOf( o.getValue('unit-price') );
		// test with USD and ?
		opp.currency__c = o.getElementByTagName('order-total').getAttribute('currency'); 	
		
		opp.email_allowed__c = Boolean.valueof(
			(o.getValue('email-allowed')=='true'?true:false) 
		);
		
		// add support for merchant-codes to specify a campaign ID
		try { if (o.getValue('merchant-item-id') != null  ) {
			opp.campaignid = o.getValue('merchant-item-id');
			}
		} catch (system.stringexception e) { 
			system.debug('ignored invalid campaign id :'+e);
			// allow bogus data in the merchant id field, just in case
		}
	}
				
	/* 
	 * map an XML element from google into a force.com contact record
	 */
	public Contact getContact(XmlDom.Element ele) {
		Contact ret = new Contact();
		ret.email = ele.getValue('email');
		XmlDom.Element billing = ele.getElementByTagName('buyer-billing-address');
		XmlDom.Element shipping = ele.getElementByTagName('buyer-shipping-address');
		
		// split full name into first and last
		ret.firstname = GetFirstAndLast(billing.getValue('contact-name'))[0];
		ret.lastname = GetFirstAndLast(billing.getValue('contact-name'))[1];
		ret.MailingCity = billing.getValue('city');
		ret.MailingStreet = billing.getValue('address1');
		if ( billing.getValue('address2') != null ) { 
		ret.MailingStreet += '\n' + billing.getValue('address2') ;
		} 
		ret.mailingPostalCode = billing.getValue('postal-code');
		ret.mailingCountry = billing.getValue('country-code');
		ret.mailingState = billing.getValue('region');

		ret.otherCity = shipping.getValue('city');
		ret.otherStreet = shipping.getValue('address1');
		if ( shipping.getValue('address2') != null ) { 
			ret.otherStreet += '\n' + shipping.getValue('address2') ;
		} 
	
		ret.otherPostalCode = shipping.getValue('postal-code');
		ret.otherCountry = shipping.getValue('country-code');
		ret.otherState = shipping.getValue('region');
		
		// external id from google checkout	
		ret.Google_Buyer_id__c = ele.getValue('buyer-id'); 
		return ret;	
	}
	string[]  GetFirstAndLast(string fullname)  {
        string[] parts = fullname.Split(' ');
        string first = parts[0];
        string last = parts[parts.size() -1];
        return new string[]{ first, last }; 
    }
	
 

 	/* check some limits */
	Integer l_callout = Limits.getLimitCallouts();
  	Integer l_stmts = Limits.getLimitScriptStatements(); 
  	Integer delta = 0;
  	boolean limit_near() {return limit_near('');}
	boolean limit_near(string msg) { // if we are too close return true
    	if ( Limits.getCallouts() >= l_callout-5  ) return true;
    	// report on number of statements and number of orders
// 		if(debug>0) {
 		//	system.debug(msg+' ' +' getLimitCallouts()    max('+l_callout + ') ' +Limits.getCallouts()); 
  			system.debug(msg+' getScriptStatements() max(' + 
  				l_stmts + ') ' +Limits.getScriptStatements() + ' delta:'+
  				(Limits.getScriptStatements() - delta));
  			delta =  Limits.getScriptStatements();
	//	}
    	return false;	
    }



	// actually goes back 60 days at this point
	public void clearLastRun() { setLastRun(system.now().addMonths(-3)); }
	
	public string getReportsEndpoint() {  
		return getEndpoint() + '/reports/Merchant/' + getMerchant_ID();
	}
	public string getRequestFormEndpoint() {  
		return getEndpoint() + '/requestForm/Merchant/' + getMerchant_ID();
	}
	public string getEndpoint() { 
		string ret = checkout;  
		if ( merchantInfo.Use_Sandbox__c ) { ret = sandbox; }  
		return ret;
	}	

public class UserAgent { integer debug= 4;

	public transient HttpResponse response_v = null;
	public string authKey = null;
	public string gsessionid; 
	//transient  XMLDom dom = null;
	
	// default some stuff for the user agent, for gdata
	public UserAgent() { }
	public UserAgent(string tok) { authKey = tok;	}
	public HttpResponse get(string url) { return request('GET',url,null);}
	public HttpResponse post(string url,string body) { return request('POST',url,body);}
	public HttpResponse getResponse() {	return response_v;	}
	public integer getStatusCode() { return response_v.getStatusCode();}
	public string getBody() {		return response_v.getBody();	}
	public XmlDom getResponseDom() { 
		//if ( dom!= null ) return dom;
		//dom = new xmldom( response_v.getBody() ); 
		return new xmldom( response_v.getBody() ); 
	}	
	
	public HttpResponse request(string method, string url) { 
		return request( method,  url, null); 
	}
	public HttpResponse request(string method, string url, string body)  { 
		HttpRequest req = new HttpRequest();   
		req.setEndpoint(url); 		
		req.setMethod(method);
		if (debug>4) system.debug(body);
		req.setBody(body);
		
		system.assert(authKey!= null ,'missing basic auth key') ;
		req.setHeader('Authorization','Basic '+authKey);
		req.setHeader('Content-Type','application/xml;charset=UTF-8');
		req.setHeader('Accept','application/xml;charset=UTF-8');
		
		if (debug>4) system.debug(req);
		req.setCompressed(true);
		
		if (body != null) req.setBody(body);
		try {
			Http http = new Http();
			response_v = http.send(req);
			System.debug('STATUS:'+response_v.getStatus());
		/*	if ( response_v.getStatusCode() == 412 ) { // status if no gsession passed in
				this.gsessionid = response_v.getHeader('X-Redirect-Location').split('gsessionid=')[1];
				response_v = request(method, url, body); // call back again to respond to this redirect
			}*/
/*			if (response_v.getStatusCode() != 200 ) {
				System.debug('STATUS:'+response_v.getStatus());
				System.debug('STATUS_CODE:'+response_v.getStatusCode());
				System.debug('BODY: '+response_v.getBody());
			}*/
			
		} catch( System.Exception e) {
			System.debug('ERROR: '+ e);
		}
		return response_v;
	}

}
class old { 
		public string getTDate(datetime dt) { 
		return string.valueofgmt(dt).replace(' ','T');	  
	}
	
/*
	string getOrderListRequest(datetime sd, datetime ed) { 
		// if the start date is within the hour, back it up to ensure we have an overlap
		endDate = ed; // save this
		string ret = getXml( '<order-list-request xmlns="http://checkout.google.com/schema/2" '+
	 		' start-date="'+ getTDate(sd.addHours(-2) ) + '" end-date="'+getTDate(ed)+'" >'+
	  		'</order-list-request>' );
	  	if(debug>0) system.debug(ret); 
	  	return ret;	
	} 
	*/
	public set<string>  processRecentOrdersResponse(string body) {
		set<string> ret = new set<string>{}; 		
		
		// parse the result, it will contain CSV with order numbers in the first column 
		// or a no orders note 'No orders were found for this request:\n blah, blah
		// TODO should check for error xml message here?
		
		string[] rl = body.split('\\n');
		STRING header = rl.remove(0);	
	//	if (debug > 1) system.debug('header :'+header);
		
		Pattern po = Pattern.compile('^[0-9]*');  // google order numbers are numerals
		
		for (string s : rl) {  			//system.debug(s);
			string onum = s.split('\\,')[0];
			// check for valid order numbers before stuffing into the list
			if ( po.matcher(onum).matches() ) {	
				ret.add( onum );
			}
		}	
		
		// CANT do this here...
		//	
		// add any orders that appear in the new state, these come in from the mail catcher
/*TODO fix me
		for (opportunity op:[select id,google_order_number__c from opportunity where fulfillment_order_state__c = 'NEW']) {
			system.debug('new order :'+op);
			ret.add( op.google_order_number__c );
		}
*/		
	//	if (debug >1) system.debug(ret);
		return ret;
	}
	
} // old
}