codeunit 50100 "Test Run Mgt."
{
    trigger OnRun()
    var
        CALTestSuiteLoc: Record "CAL Test Suite";
        CALTestLineLoc: Record "CAL Test Line";
        CALTestManagementLoc: Codeunit "CAL Test Management";
    begin
        CALTestSuiteLoc.FindFirst;
        CALTestLineLoc.SetRange("Test Suite", CALTestSuiteLoc.Name);
        CALTestLineLoc.FindFirst;
        CALTestManagementLoc.RunSuite(CALTestLineLoc, true);
    end;

    /// <summary>
    /// Runs all Test functions from the first test suite
    /// </summary>
    /// <returns>Output all functions which are run and the result</returns>
    procedure RunFromWebservice(): Text
    var
        CALTestSuiteLoc: Record "CAL Test Suite";
        CALTestLineLoc: Record "CAL Test Line";
        TempBlobLoc: Codeunit "Temp Blob";
        CALTestManagementLoc: Codeunit "CAL Test Management";
        KMExportCALTestLineLoc: XMLport "Export CAL Test Line";
        OutStreamLoc: OutStream;
        InStreamLoc: InStream;
        ReadTextLoc: Text;
        XMLTextLoc: Text;
    begin
        //Run the Test Suite
        CALTestSuiteLoc.FindFirst;
        CALTestLineLoc.SetRange("Test Suite", CALTestSuiteLoc.Name);
        CALTestLineLoc.FindFirst;
        CALTestManagementLoc.RunSuite(CALTestLineLoc, true);
#pragma warning disable AA0175
        CALTestLineLoc.FindFirst;
#pragma warning restore AA0175

        //Write CAL test Line Table into a blob in XML format and iteratively create the return text of this function
        TempBlobLoc.CreateOutStream(OutStreamLoc);
        KMExportCALTestLineLoc.SetDestination(OutStreamLoc);
        KMExportCALTestLineLoc.Export;
        TempBlobLoc.CreateInStream(InStreamLoc);
        while not InStreamLoc.EOS do begin
            InStreamLoc.Read(ReadTextLoc, 1024);
            XMLTextLoc += ReadTextLoc;
        end;
        exit(XMLTextLoc);
    end;

    /// <summary>
    /// Initializes the test suite
    /// </summary>
    /// <param name="TestCodeunitFilter">A filter string which contains the ids of test codeunits which have to be run.
    /// E.g. '50101..50110'
    /// </param>
    procedure InitializeTestRun(TestCodeunitFilter: Text)
    begin
        DeleteAndCreateTestSuite;
        AddTestCodeunitsToSuite(TestCodeunitFilter);
    end;

    /// <summary>
    /// Deletes all existing test suites
    /// </summary>
    local procedure DeleteAndCreateTestSuite()
    var
        CALTestSuiteLoc: Record "CAL Test Suite";
    begin
        //Delete all Test Suites
        if not CALTestSuiteLoc.IsEmpty then
            CALTestSuiteLoc.DeleteAll(true);

        //Create the Test Suite
        CALTestSuiteLoc.Init;
        CALTestSuiteLoc.Name := 'DEFAULT';
        CALTestSuiteLoc.Insert;
    end;

    /// <summary>
    /// Adds all tets codeunits from the filter to the test suite
    /// </summary>
    /// <param name="TestCodeunitFilter">The filter which contains the tets codeunit ids</param>
    local procedure AddTestCodeunitsToSuite(TestCodeunitFilter: Text)
    var
        AllObjWithCaptionLoc: Record AllObjWithCaption;
        CALTestSuiteLoc: Record "CAL Test Suite";
        iLoc: Integer;
    begin
        //init variable
        iLoc := 1;

        //Get The test Suite
        CALTestSuiteLoc.Get('DEFAULT');

        //Find the specified Test Codeunits
        AllObjWithCaptionLoc.SetRange("Object Type", AllObjWithCaptionLoc."Object Type"::Codeunit);
        AllObjWithCaptionLoc.SetRange("Object Subtype", 'Test');
        if TestCodeunitFilter <> '' then
            AllObjWithCaptionLoc.SetFilter("Object ID", TestCodeunitFilter);
        if AllObjWithCaptionLoc.FindSet then
            repeat
                //Add a line to the Test Suite for every Test Codeunit found
                AddTestLine(CALTestSuiteLoc.Name, AllObjWithCaptionLoc."Object ID", iLoc * 10000);
                iLoc += 1;
            until AllObjWithCaptionLoc.Next = 0
        else
            exit;
    end;

    local procedure AddTestLine(TestSuiteNamePar: Code[10]; TestCodeunitIDPar: Integer; LineNoPar: Integer)
    var
        CALTestLineLoc: Record "CAL Test Line";
        CALTestManagementLoc: Codeunit "CAL Test Management";
    begin
        //Add the Test Codeunit to the Test Suite
        CALTestLineLoc.Init;
        CALTestLineLoc.Validate("Test Suite", TestSuiteNamePar);
        CALTestLineLoc.Validate("Line No.", LineNoPar);
        CALTestLineLoc.Validate("Line Type", CALTestLineLoc."Line Type"::Codeunit);
        CALTestLineLoc.Validate("Test Codeunit", TestCodeunitIDPar);
        CALTestLineLoc.Validate(Run, true);
        CALTestLineLoc.Insert(true);

        //Run the Test Codeunit after it is added
        CALTestManagementLoc.SETPUBLISHMODE;
        CALTestLineLoc.SetRecFilter;
        CODEUNIT.Run(CODEUNIT::"CAL Test Runner", CALTestLineLoc);
    end;
}