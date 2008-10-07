global class GoogCheckoutEmailCatcher  implements Messaging.InboundEmailHandler {
   	
    global Messaging.InboundEmailResult handleInboundEmail(Messaging.InboundEmail email, Messaging.InboundEnvelope envelope) {
        Messaging.InboundEmailResult result = new Messaging.InboundEmailresult();
        
		string body = email.plaintextbody;
		       
		// create a donation record as opportunity 
		
		// https://sandbox.google.com/checkout/sell/multiOrder?order=730741324660384
		
		opportunity d = new opportunity();
		d.Google_Order_Number__c = getMatching('Google\\sOrder\\s*#([\\d]*)',body);
		if ( d.Google_Order_Number__c == null ) { 
			// this is not an order, just return
			return result;
		}
		 
		// make a callout to get the full details on this order
		// 
		
		// amount of the donation
		d.amount = double.valueof(getMatching('Total:\\s*\\$([\\d\\.]*)\\s',body));
		
		// TODO use the date we parse out of the description if possible
		d.closeDate = System.today();
		
		// put the description in the name
		d.name = getMatching('(?s)Price(.*?)-',body);		
		if ( getMatching('^[\\d ]*(.*)',d.name ) !=null ) {
			d.name = getMatching('^[\\d ]*(.*)',d.name );
		}
		if (d.name == null) { 
			d.name = 'donation'; // default if we can't match a donation
		}

		system.debug('name is >'+d.name+'<');
		
		// other donation defaults
		d.stagename = 'Closed';
		d.description = body; 
		
		system.debug(d);
		// see if a donation exists first, then do an upsert
		integer count = [Select count() From Opportunity o
		   	where o.google_order_number__c = : d.Google_Order_Number__c ];
		system.debug('found existing order :'+count);
		if (count == 0) {
			insert d;
    	}
		// apply the who if we can discover it.
		string who = getMatching('\\*\\s*(.*)\\* has just completed a purchase',body);
		if( who == null ) 
			who = getMatching('^\\s+(.*) has just completed a purchase',body);
		system.debug('who is >'+who + '<');
		if ( who != null && count ==0) { 
			try { 
				contact c = null; 
				try { c = [select id from contact where email = :who limit 1]; } catch(exception e) { 
					system.debug('ignored: '+e); 
				} 
				system.debug('existing contact '+c);
				if (c == null) { 
					Account a = [ select id from account where name = 'Individual' limit 1];
					
					c = new contact();
					if (a != null) { 
						c.accountid = a.id;
					}
					c.email = who;
					c.lastname = who;
					insert c;
				}
				makeContactRole(c.id, d.id);
				
			} catch(exception e) { 
				system.debug(e);	
			} 

		}
		
		// if this is a google checkout email, process a donation , cancel or refund action  
        return result;
    }
    
	private string getMatching(string patern, string body) {
		Pattern p = Pattern.compile(patern);
 		Matcher m = p.matcher(body);
 		string ret = null;
 		if ( m.find() ) { 
 			ret = m.group(1);
 		}
 		return ret;	
	}

	private void makeContactRole(id cid,id oid) {
		opportunitycontactrole r = new opportunitycontactrole();
		r.contactid = cid;
		r.opportunityid = oid;
		r.role = 'Donor';
		insert r;
		system.debug(r);
	}
}