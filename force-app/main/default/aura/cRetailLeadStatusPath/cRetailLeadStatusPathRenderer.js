({
	// Your renderer method overrides go here
	afterRender : function(component,helper){
        this.superAfterRender();
       

         console.log('After Render');
         
       var elements =  document.getElementsByClassName("slds-path__item:last-child");
      //   var elements = document.getElementsByClassName("myTest");
        console.log("elements.length: " + elements.length);
        for (var i=0; i<elements.length; i++) {
            console.log(elements[i].innerHTML);
        }
        
    }
})