public class GoogCheckoutEmailTest {
 
	// test if contact does not exist, should create contact
	static testMethod void t2() {

		// Create a new email and envelope object
	   	GoogCheckoutEmailCatcher gc = new GoogCheckoutEmailCatcher(); 
	  	// gc.debug = 5;
	   
	   // build email message to test with
	   Messaging.InboundEmail email = new Messaging.InboundEmail() ;
	   Messaging.InboundEnvelope env 	= new Messaging.InboundEnvelope();

	   email.plaintextbody = '[image: Google Checkout] Hello * sfdccheckout@gmail.com*,\n\n'+
		'* sfdctestbuyer2@gmail.com* has just completed a purchase from your store.\n'+
		'Below is the summary of the transaction. Donation Details - Mar 3, 2008\n'+
		'2:32 PM CST\n'+
		'Google Order #3016082212198181 Qty Item Price 1 *Donate Livestock* -\n'+
		'An entire family thanks you $220.00 Total: $220.00\n';
	   
	   gc.handleInboundEmail(email, env ); // do it
	   
	   // see if the opp, contact and role are created
	   opportunity o = [Select o.id, (Select Id, Role, IsPrimary From OpportunityContactRoles) 
	   	From Opportunity o
	   	where o.google_order_number__c = '3016082212198181' limit 1];
	   system.assert(o!=null,' missing opportunity ');
	   system.assert(o.opportunitycontactroles != null, ' missing opp role' );	
	   
	}
	
	// test second time with same order number, does not create new record
	static testMethod void duplicate_donations() {
		// Create a new email and envelope object
	   	GoogCheckoutEmailCatcher gc = new GoogCheckoutEmailCatcher(); 
	  
	   	// build email message to test with
	   	Messaging.InboundEmail email = new Messaging.InboundEmail() ;
	   	Messaging.InboundEnvelope env 	= new Messaging.InboundEnvelope();

	   	email.plaintextbody = '[image: Google Checkout] Hello * sfdccheckout@gmail.com*,\n\n'+
		'* sfdctestbuyer2@gmail.com* has just completed a purchase from your store.\n'+
		'Below is the summary of the transaction. Donation Details - Mar 3, 2008\n'+
		'2:32 PM CST\n'+
		'Google Order #3016082212198181 Qty Item Price 1 *Donate Livestock* -\n'+
		'An entire family thanks you $220.00 Total: $220.00\n';
	   
		gc.handleInboundEmail(email, env ); // do it
		gc.handleInboundEmail(email, env ); // do it
    
	   	// see if the opp, contact and role are created
	   	opportunity[] o = [Select o.id, (Select Id, Role, IsPrimary From OpportunityContactRoles) 
		   	From Opportunity o
		   	where o.google_order_number__c = '3016082212198181' ];
		system.assert(o.size()==1,' duplicate donation opps created');
		//system.debug(o.size());
	   	system.assert(o!=null,' missing opportunity ');
	   
	}	
	
	// with matching contact, should create a contact role
	static testMethod void t3() {
		// Create a new email and envelope object
	   GoogCheckoutEmailCatcher gc = new GoogCheckoutEmailCatcher(); 

	    
	   // build a buyer contact record
	   contact con = new contact();
	   con.lastname = 'test'; 
	   con.email = 'sfdctestbuyer2@gmail.com'; 
	   insert con;
	   
	   // build email message to test with
	   Messaging.InboundEmail email = new Messaging.InboundEmail() ;
	   Messaging.InboundEnvelope env 	= new Messaging.InboundEnvelope();

	   email.plaintextbody = 'From: Google Checkout <noreply@checkout.google.com>' + 
		'Date: Wed, Feb 27, 2008 at 6:44 PM\n'+
		'Subject: Purchase Receipt for Order #730741324660381\n'+
		'To: sfdccheckout@gmail.com\n'+
		'\n'+
		'\n'+
		'[image: Google Checkout] Hello * sfdccheckout@gmail.com*,\n'+
		'\n'+
		'* sfdctestbuyer2@gmail.com* has just completed a purchase from your store.\n'+
		'Below is the summary of the transaction. Donation Details - Feb 27, 2008 8:44 PM CST\n'+
		'Google Order #730741324660381 Qty Item Price 1 *Donate to our Cause* - \n'+
		'Your contribution is not forgoten $20.00 Total: $20.00\n';		
	   
	   gc.handleInboundEmail(email, env ); // do it
	   
	   // see if the opp, contact and role are created
	   opportunity o = [Select o.id, (Select Id, Role, IsPrimary From OpportunityContactRoles) 
	   	From Opportunity o
	   	where o.google_order_number__c = '730741324660381' limit 1];
	   system.assert(o!=null,' missing opportunity ');
	   system.assert(o.opportunitycontactroles != null, ' missing opp role' );	
	   
	} 
	
	// should not create an opp, bady email , not an order
	static testMethod void t4() {
		// Create a new email and envelope object
	   GoogCheckoutEmailCatcher gc = new GoogCheckoutEmailCatcher(); 

	   
	   // build email message to test with
	   Messaging.InboundEmail email = new Messaging.InboundEmail() ;
	   Messaging.InboundEnvelope env 	= new Messaging.InboundEnvelope();

	   email.plaintextbody = 'bad body';
	   
	   gc.handleInboundEmail(email, env ); // do it
	  
	} 
	
   
}