xmlport 50100 "Export CAL Test Line"
{
    Direction = Export;
    Encoding = UTF8;
    schema
    {
        textelement(root)
        {
            tableelement("CAL Test Line"; "CAL Test Line")
            {
                XmlName = 'CALTestLine';
                fieldelement(TestSuite; "CAL Test Line"."Test Suite")
                {
                }
                fieldelement(LineNo; "CAL Test Line"."Line No.")
                {
                }
                fieldelement(LineType; "CAL Test Line"."Line Type")
                {
                }
                fieldelement(TestCodeunit; "CAL Test Line"."Test Codeunit")
                {
                }
                fieldelement(CALTestLineName; "CAL Test Line".Name)
                {
                }
                fieldelement(CALTestLineFunction; "CAL Test Line".Function)
                {
                }
                fieldelement(CALTestLineRun; "CAL Test Line".Run)
                {
                }
                fieldelement(CALTestLineResult; "CAL Test Line".Result)
                {
                }
                fieldelement(CALTestLineFirstError; "CAL Test Line"."First Error")
                {
                }
                fieldelement(StartTime; "CAL Test Line"."Start Time")
                {
                }
                fieldelement(FinishTime; "CAL Test Line"."Finish Time")
                {
                }
                fieldelement(Level; "CAL Test Line".Level)
                {
                }
                fieldelement(HitObjects; "CAL Test Line"."Hit Objects")
                {
                }
            }
        }
    }
}