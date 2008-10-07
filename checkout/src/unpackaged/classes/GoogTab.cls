public class GoogTab {
	Google_Merchant__c  m;  
	public googTab() { 
	}
	public googTab(ApexPages.StandardController controller) { 
	}
    public string getTotalOrders() { 
    	integer count = [ select count() from Opportunity 
    		where google_order_number__c != null];
    	return string.valueof(count);	
    }
	public string getLastRun() { 
		this.m = [ Select  g.Id, g.Last_Update_Run__c , 
		  g.lastmodifieddate From Google_Merchant__c g 
			limit 1];
	/*	system.debug('updated at '+m);	
		system.assert(m!=null);
		if (m.last_update_run__c == null) {
			m.last_update_run__c = system.now().addmonths(-3);	
		}
*/
		return m.lastmodifieddate.format('EEE, d MMM yyyy HH:mm:ss');
		 
	}

    public PageReference updateOrders() {  
    	GoogCheckout g = new GoogCheckout();
    	g.setContinueToken( system.now().adddays(-1) );
     	g.getAllBatches( );
      	return null;
    }
    public PageReference updateOrders30() {  
       GoogCheckout g = new GoogCheckout();
     	g.setContinueToken( system.now().addmonths(-1) );
     	g.getAllBatches( );
      	return null;
    }
    
    /* orders in the past few hours */
    opportunity[] recent;
    public opportunity[] getPastHour() { 
    	recent = [Select o.Quantity__c, o.Name, o.Fulfillment_Order_State__c, 
    			o.Financial_Order_State__c, o.Amount, o.Order_Creation_Date__c, createddate,
    			o.item_description__c, o.Google_Order_Number__c
    			From Opportunity o 
    			where o.Order_Creation_Date__c >= :System.now().addHours(-25) 
    			or o.CreatedDate >= :System.now().addHours(-25) 
    			order by Order_Creation_Date__c desc];
    	return recent; 
    }

    
	/* simple test methods 
	 */
	public static testmethod void test1()  {
		googtab t = new googtab();
		t.getLastRun();
		t.updateOrders();
	}
	public static testmethod void test2()  {	
		googtab t = new googtab();
		t.updateOrders();	
	}
	public static testmethod void test3()  {	
		googtab t = new googtab();
		t.updateOrders30();	
	}
	public static testmethod void test4()  {	
		googtab t = new googtab();
		t.getPastHour();
	}
}