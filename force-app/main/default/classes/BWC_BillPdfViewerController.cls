public with sharing class BWC_BillPdfViewerController {

    public Boolean isBusy {get; set;}
    public Boolean isPdfReturned {get; set;}
    public transient String pdfDataUrl {get; set;}

    private String product;
    private String statementId;

    public BWC_BillPdfViewerController() {

        this.product = ApexPages.currentPage().getParameters().get('product');
        this.statementId = ApexPages.currentPage().getParameters().get('statementId');

        // Page starts with spinner
        this.isBusy = true;

    }

    /*
        Call service to get PDF. This is called from action function, which allows spinner to show while waiting.
    */
    public PageReference getBillPdf() {

        try {

            // Get the PDF
            BWC_BillingDetails.BillPdfResponse response = BWC_BillingDetailsService.getBillPdf(product, statementId);

            if (response.content == null) {

                String message = 'Error retrieving PDF.';
                if (response.error != null) {
                    message = 'Error retrieving PDF: ' + JSON.serialize(response.error);
                }

                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, message));

            }
            else if (response.content.pdfReturned == true) {

                // Success -- set the data URL for the iframe
                this.isPdfReturned = true;
                this.pdfDataUrl = 'data:application/pdf;base64,' + response.content.pdfData;

            }
            else {

                // Failure, show with error code
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'PDF not returned. Error Code: ' + response.content.ErrorCode));

            }

        }
        catch (System.Exception e) {

            // Other failure
            ApexPages.addMessages(e);

        }
        finally {

            // Cancel spinner
            this.isBusy = false;

        }

        return null;

    }

}