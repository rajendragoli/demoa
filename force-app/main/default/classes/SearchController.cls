public with sharing class SearchController {

    public SearchController(ApexPages.StandardSetController controller) {

    }


    public String isSegmentSwitchActive { get; set; }

    public String autoSearchCharLimit { get; set; }

    public String noOfPatientPrimaryFields { get; set; }

    public String Patient { get; set; }

    public String currentDivision { get; set; }

    public String recordPerPage { get; set; }

    public String isDefaultASC { get; set; }

    public String defaultSortBy { get; set; }

    public String errorMessage { get; set; }

    public String maxResult { get; set; }

    public String isError { get; set; }

    public String orgNameSpacePrefix { get; set; }
}