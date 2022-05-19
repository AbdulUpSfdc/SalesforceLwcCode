import * as BwcUtils from 'c/bwcUtils';
import search from "@salesforce/apex/SearchController.search";

export const customLookupData = async (objName,fields,searchKey) => {
    const searchresponseJson = await search({objectName : objName,fields : fields, searchTerm : searchKey});
    BwcUtils.log('response from Custom Lookup '+JSON.stringify(searchresponseJson));
    return searchresponseJson;
}