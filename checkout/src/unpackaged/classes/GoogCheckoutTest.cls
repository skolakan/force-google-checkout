public class GoogCheckoutTest {
 	public static testmethod void t_setContinueToken()  { 
 		GoogCheckout g = new GoogCheckout();  
		g.setContinueTokenUpdate(system.now().addMonths(-3));
 	}
	public static testmethod void testgetOneBatch()  { 
 		GoogCheckout g = new GoogCheckout();  
		g.getOneBatch();
 	}
	public static testmethod void testgetAllBatches()  { 
 		GoogCheckout g = new GoogCheckout();  
		g.setContinueToken(system.now().addMonths(-1));
		g.debug = 1;
		g.getAllBatches();
 	}
	public static testmethod void testupdateOrders()  { 
 		GoogTab t = new GoogTab();  
		t.updateOrders();
 	}	
	public static testmethod void test1()  { 
		GoogCheckout g = new GoogCheckout();
		system.debug( g.getRequestFormEndpoint() );
		system.debug( g.getReportsEndpoint() );
		System.debug( g.ua.getResponse() ); 
		System.debug( g.getMerchant_Key() );  
	} 
	
	public static testmethod void test2()  {

		goognotification.tokenrequest(system.now());

		/*
		System.debug('BODY: '+ g.getResponseBody());	

		g.makeRequest( g.getReportsEndpoint(), g.getNotificationRequest2(
			new string []{'233218189938542'}  )); 
	//	System.debug('BODY: '+ g.getResponseBody());
		XMLDom d = g.createDocument(); 
		d.dumpAll();
		d.dumpList(  d.getElementsByTagName('order-state-change-notification') );
		for ( XMLDom.Element e:d.getElementsByTagName('order-state-change-notification') ) {
			system.debug( e.getElementsByTagName('new-fulfillment-order-state')[0].nodeValue );	
		}
		*/
	}
	
		
	public static testmethod void test3()  {
		/*
		GoogCheckout g = new GoogCheckout(); g.debug=3;	
		// send a request
		g.ua.post( g.getRequestFormEndpoint(), '_type=hello');
			
		// invalid order number
		g.makeRequest( g.getReportsEndpoint(), // 'https://sandbox.google.com/checkout/api/checkout/v2/reports/Merchant/' + g.mid	,
		 '<?xml version="1.0" encoding="UTF-8"?><notification-data-request xmlns="http://checkout.google.com/schema/2">'+
		 '<order-numbers>'+
		 '<google-order-number>3773456810251373</google-order-number></order-numbers>'+
		 '<notification-types><notification-type>new-order</notification-type></notification-types>'+
		 '</notification-data-request>');
		// response is in g.res.getBody();
		System.debug('BODY: '+ g.getResponseBody());
		XMLDom d = g.ua.getResponseDom(); 
		d.dumpAll();
		d.getElementsByTagName('invalid-order-numbers')[0].dumpAll();
		
		// works, returns 3 orders in report format
		g.makeRequest( g.getReportsEndpoint() ,
		'<?xml version="1.0" encoding="UTF-8"?><order-list-request xmlns="http://checkout.google.com/schema/2" '+
 		' start-date="2008-03-01T00:00:00" end-date="2008-03-04T23:59:59">'+
  		'<date-time-zone>America/New_York</date-time-zone></order-list-request>');	
  		System.debug('BODY: '+ g.getResponseBody());
  			*/
	} 

	public static testmethod void test4()  {
		GoogCheckout g = new GoogCheckout();	
		g.debug=3;
		XMLdom d = new xmldom(testNotification); 
		
		XMLDom.Element[] notifs = d.getElementsByTagName('new-order-notification');
		notifs.addAll( d.getElementsByTagName('order-state-change-notification') );
		
		for (XMLDom.Element s: notifs ) {
			system.debug ( s.nodeName ); // one of the two types
			s.dump(); 
			s.dumpAll();
		}
	}		
	
	
	/*public static testmethod void test5()  {
		GoogCheckout g = new GoogCheckout();	
		//system.debug ( g.formatDateString(system.now()) );
		system.debug( system.now() );
		datetime d = system.now();
	//	String timeFormat = d.formatGmt('YYYY ee dd HH:mm:ss') + '.000Z';
	//	system.debug(timeFormat);
		system.debug ( string.valueofgmt(d).replace(' ','T') );
		d = d.addMonths(-1); // back 30 days
		system.debug ( g.getTDate(d) );
		system.debug( g.getPastMonth() );
		g.makeRequest( g.getReportsEndpoint() , g.getPastMonth() );
		system.debug( g.getResponse() );
		System.debug('BODY: '+ g.getResponse().getBody());
		
	}  */
	
	// <timestamp>2008-03-04T20:56:40.606Z</timestamp>
	public static testmethod void test6()  {
	//	system.debug( Datetime.parse('Mar 4, 2008 3:56:40 PM') );
		string tt = '2008-03-04T20:56:40.606Z';
		tt = tt.replace('T', ' ');	
		system.debug( Datetime.valueOfGmt(tt) );
	}	
	
/*	public static testmethod void test8()  {
		GoogCheckout g = new GoogCheckout();	
		// times specified must be 60 min in the past
  		string request =g.getOrderNotifications(system.now().addMonths(-1),system.now().addHours(-1)) ;
  		system.debug (request); 
  		g.makeRequest( g.getReportsEndpoint() , request	);
  		system.debug( g.getResponseBody()  );
	}	*/
		
	// test getNotificationRequest() with a live request
	// should be run from execute Ananymous window to see results
	public static testmethod void test7()  {
		/*
		GoogCheckout g = new GoogCheckout();	g.debug=3;
		// fetch a single notification 377345681025137
		string req = g.getNotificationRequest( new string[]{'468764334174551'} );  
		
		req = g.getNotificationRequest( new string[]{'661372026658675'} );  
		
		// 2 orders is about 9867 bytes, so 32k requires chunks of 
		system.debug (req);
		g.makeRequest( g.getReportsEndpoint() , req );
		
		XMLDom d = g.createDocument(); 
		
		//string ret = g.getResponseBody();	system.debug(ret);

		XMLDom.Element[] olist = new XMLDom.Element[]{}; 
		olist.addAll( d.getElementsByTagName('new-order-notification') );
	  	olist.addAll( d.getElementsByTagName('order-state-change-notification') );		
		
		// take a list of orders, pull out the list of order ID's
		set<string> oids = new set<string>{};
		for (XMLDom.Element o :olist) {  
			oids.add( o.getValue('google-order-number') ); 
		}
		system.debug (oids);
		
		system.debug(olist);
		
		Contact c = g.getContact(olist[0]);
		system.debug(c );
		insert c;
		system.assert( c.id !=null);
		// insert c;
		// upsert opps google_order_number__c;
		*/
	}
	
	
	// verify merchant item id has a campaign
 	public static testmethod void test8()  {
	/*	GoogCheckout g = new GoogCheckout();	g.debug=3;
		// fetch a single notification 377345681025137
		string req = g.getNotificationRequest( 
			new string[]{'369131295258560'} );  
		
		g.makeRequest( g.getReportsEndpoint() , req );
		XMLDom d = g.createDocument(); 
		XMLDom.Element[] olist = new XMLDom.Element[]{}; 
		olist.addAll( d.getElementsByTagName('new-order-notification') );
		d.dumpAll();
		
		set<string> oids = new set<string>{};
		for (XMLDom.Element o : olist ) {  
			 
			system.debug(' for order : '+ o.getValue('google-order-number') ); 
			system.debug(' campaign id is: '+
				o.getValue('merchant-item-id')); 
		}
		*/
	}


		
	// like test7 but without the call to make request..
	// TODO test with and without a matching contact
	// to verify that the contact is created
	public static testmethod void test11()  {
		GoogCheckout g = new GoogCheckout();	
		g.debug = 2;
		XMLDom d = new xmldom( testNotification); 
		XMLDom.Element[] olist = new XMLDom.Element[]{}; 
		olist.addAll( d.getElementsByTagName('new-order-notification') );
		
		//system.debug(olist);
		// take a list of orders, pull out the list of order ID's
		/*set<string> oids = new set<string>{};
		for (XMLDom.Element o :olist) {  
			oids.add( o.getValue('google-order-number') ); 
		}
		system.debug (oids);
		*/
		
		// create the opportunities if any are missing
		//opportunity[] opps = g.createOpportunities(olist);
/*		g.processNotificationOrderList(
			d.getElementsByTagName('new-order-notification'),
			 d.root.getElementsByTagName('order-state-change-notification')
			); 
*/
	}

	
 		

	static string testNotification = '<?xml version="1.0" encoding="UTF-8"?>' +
'<notification-data-response xmlns="http://checkout.google.com/schema/2" serial-number="9d0e62c6-afc8-44ce-a985-180b37356059">' + 
'  <notifications>' + 
'   <new-order-notification  serial-number="377345681025137-00001-7">' + 
      '<timestamp>2008-03-04T20:56:40.606Z</timestamp>' + 
      '<buyer-id>756525894341880</buyer-id>' + 
      '<shopping-cart>' + 
        '<items>' + 
          '<item>' + 
          '  <merchant-item-id>33</merchant-item-id> '+
            '<item-name>Donate to our Cause</item-name>' + 
            '<item-description>Thank you for your contribution!</item-description>' + 
            '<unit-price currency="USD">55.0</unit-price>' + 
            '<quantity>1</quantity>' + 
          '</item>' + 
        '</items>' + 
      '</shopping-cart>' + 
      '<order-adjustment>' +  
        '<merchant-codes />' + 
        '<total-tax currency="USD">0.0</total-tax>' + 
       '<adjustment-total currency="USD">0.0</adjustment-total>' + 
     '</order-adjustment>' + 
     '<google-order-number>377345681025137</google-order-number>' + 
     '<buyer-shipping-address>' + 
       '<email>sfdctestbuyer2@gmail.com</email>' + 
       '<company-name></company-name>' + 
       '<contact-name>Bob Cardholder</contact-name>' + 
       '<phone></phone>' + 
       '<fax></fax>' + 
       '<address1>1234 MainShipping St.</address1>' + 
       '<address2>apt 2</address2>' + 
       '<country-code>US</country-code>' + 
       '<city>Moline</city>' + 
       '<region>TX</region>' + 
       '<postal-code>61265</postal-code>' + 
     '</buyer-shipping-address>' + 
     '<buyer-billing-address>' + 
       '<email>sfdctestbuyer2@gmail.com</email>' + 
       '<company-name></company-name>' + 
       '<contact-name>Bob Cardholder</contact-name>' + 
       '<phone></phone>' + 
       '<fax></fax>' + 
       '<address1>1234 MainBilling St.</address1>' + 
       '<address2>apt 1</address2>' + 
       '<country-code>US</country-code>' + 
       '<city>Moline</city>' + 
       '<region>IL</region>' + 
       '<postal-code>61266</postal-code>' + 
     '</buyer-billing-address>' + 
     '<buyer-marketing-preferences>' + 
       '<email-allowed>false</email-allowed>' + 
     '</buyer-marketing-preferences>' + 
     '<order-total currency="USD">55.0</order-total>' + 
     '<fulfillment-order-state>NEW</fulfillment-order-state>' + 
     '<financial-order-state>REVIEWING</financial-order-state>' + 
   ' </new-order-notification>' +

   ' <order-state-change-notification serial-number="377345681025137-00010-1">' +
     '<timestamp>2008-03-04T20:57:42.530Z</timestamp>' +
     '<google-order-number>377345681025137</google-order-number>' +
     '<new-fulfillment-order-state>PROCESSING</new-fulfillment-order-state>' +
     '<new-financial-order-state>CHARGED</new-financial-order-state>' +
     '<previous-fulfillment-order-state>PROCESSING</previous-fulfillment-order-state>' +
     '<previous-financial-order-state>CHARGING</previous-financial-order-state>' +
   ' </order-state-change-notification>' +
   ' <order-state-change-notification serial-number="377345681025137-00011-1">' +
     '<timestamp>2008-03-04T20:57:42.561Z</timestamp>' +
     '<google-order-number>377345681025137</google-order-number>' +
     '<new-fulfillment-order-state>DELIVERED</new-fulfillment-order-state>' +
     '<new-financial-order-state>CHARGING</new-financial-order-state>' +
     '<previous-fulfillment-order-state>PROCESSING</previous-fulfillment-order-state>' +
     '<previous-financial-order-state>CHARGING</previous-financial-order-state>' +
   '</order-state-change-notification> ' +
 '</notifications></notification-data-response>' ;

	
	static string testReport = 
	'Google Order Number,Merchant Order Number,Order Creation Date,Currency of Transaction,Order Amount,Amount Charged,Financial Status,Fulfillment Status\n'+
'301608221219818,301608221219818,"Mar 3, 2008 3:32:28 PM",USD,"1,220.00",220.00,CHARGED,DELIVERED\n'+
'669914837634476,669914837634476,"Mar 4, 2008 9:08:18 AM",USD,40.00,40.00,CHARGED,DELIVERED\n'+
'377345681025137,377345681025137,"Mar 4, 2008 3:56:40 PM",USD,55.00,55.00,CHARGED,DELIVERED\n';
	
	
	public static testmethod void testCreateOpps()  {
		GoogCheckout g = new GoogCheckout();	
		g.debug=2;
		Campaign camp = new Campaign(name = 'fff');
		insert camp;  

		XMLdom d = new xmldom(testNotification); 
		
		XMLDom.Element[] notifs = d.getElementsByTagName('new-order-notification');
		system.debug( notifs[0].getValue('item-name') );
		Opportunity opp = new Opportunity();
		g.element_to_opp(notifs[0],opp);
		system.assertEquals('Donate to our Cause', opp.Name );
		
/*		opportunity[] opps = g.createOpportunities( notifs );  
		upsert opps google_order_number__c;
		
		system.debug(opps[0]);
		system.assert( opps[0].id !=null );
		system.assert( opps[0].Email_Allowed__c == false );
		system.assert( opps[0].Currency__c == 'USD' );*/
	}
}