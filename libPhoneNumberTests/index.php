<!DOCTYPE html>
<html>

<?PHP
    $mode = isset($_REQUEST['test']) ? true:false;
    $metadataSrc = "./libphonenumber-read-only/javascript/i18n/phonenumbers/metadata.js";
    $fileName = "PhoneNumberMetaData";
    
    if ($mode)
    {
        $metadataSrc = "./libphonenumber-read-only/javascript/i18n/phonenumbers/metadatafortesting.js";
        $fileName = "PhoneNumberMetaDataForTesting";
    }
?>

<head>
    <title>libPhoneNumber for iOS metadata generator</title>
    <script src="http://closure-library.googlecode.com/svn/trunk/closure/goog/base.js"></script>
    <script>
        goog.require('goog.proto2.Message');
        goog.require('goog.dom');
        goog.require('goog.json');
        goog.require('goog.array');
        goog.require('goog.proto2.ObjectSerializer');
        goog.require('goog.string.StringBuffer');
    </script>
    <script src="./libphonenumber-read-only/javascript/i18n/phonenumbers/phonemetadata.pb.js"></script>
    <script src="./libphonenumber-read-only/javascript/i18n/phonenumbers/phonenumber.pb.js"></script>
    <script src=<?PHP echo '"'.$metadataSrc.'"'; ?>></script>
    <script src="./libphonenumber-read-only/javascript/i18n/phonenumbers/phonenumberutil.js"></script>
    <script src="./libphonenumber-read-only/javascript/i18n/phonenumbers/asyoutypeformatter.js"></script>
    <script src="http://code.jquery.com/jquery-1.8.3.min.js"></script>
    <script>
        goog.require('i18n.phonenumbers.metadata');
        $(document).ready(function () {
            var goodDomElement = goog.dom.getElement;
            var jsonData = encodeURIComponent(JSON.stringify(i18n.phonenumbers.metadata));
            $.ajax({
                 type: "POST",
                 url: "libPhoneNumberGenerator.php",
                data: { jsonData: jsonData, fileName: <?php echo '"'.$fileName.'"'; ?> }
                 }).done(function(msg) {
                $('#console').html(msg."");
            });
        });
    </script>
</head>

<body>
    <div id="console">Generate libPhoneNumber metadata for iOS</div>
</body>

</html>