<%@ WebHandler Language="C#" Class="DoHandler" %>

using System;
using System.Configuration;
using System.Web;
using System.Threading.Tasks;
using System.Text;
using System.IO;
using System.Drawing;
using System.Xml;


public class DoHandler : IHttpHandler
{


    HttpResponse Response;
    HttpRequest Request;

    HttpServerUtility ServerUtility;

    bool isTrueSecurityKey = false;
    string format = "xml";

    string encodingName = "utf-8";

    Encoding encoding = null;

    public void ProcessRequest(HttpContext context)
    {

        this.encoding = Encoding.GetEncoding(encodingName);

        Response = context.Response;
        Request = context.Request;
        ServerUtility = context.Server;

        Response.ContentEncoding = encoding;

        format = Request["format"] ?? "xml";



        string securityKey = Request["SecurityKey"] ?? string.Empty;

        isTrueSecurityKey = ConfigSetting.Current.SecurityKey == securityKey;

        switch (Request["action"] ?? string.Empty)
        {


            //普通用户上传图片
            case "upload":
                upload(false);
                break;

            case "serverupload":
                upload(true);
                break;

            //处理错误传输的图片
            case "uploaderrors":
                upload_errors();
                break;

            case "delete":
                delete();
                break;


            //动态输出图片
            case "dynamicecho":
                dynamic_echo();
                break;


            default:
                break;
        }
    }




    void dynamic_echo()
    {
        string path = Request.QueryString["path"] ?? string.Empty;
        string name = Request.QueryString["name"] ?? string.Empty;
        string base64 = Request.QueryString["base64"] ?? string.Empty;


        Response.ContentType = Microsoft.Win32.Registry.ClassesRoot.OpenSubKey(Path.GetExtension(name)).GetValue("Content Type", "application/octet-stream").ToString();


        string info = Base64Helper.DecodeBase64(base64);

        if (!string.IsNullOrEmpty(info))
        {

            string cacheAbsPath = ServerUtility.MapPath(ConfigSetting.Current.CachePath + path + base64 + "/" + name);


            //缓存文件已存在
            if (File.Exists(cacheAbsPath))
            {
                Response.TransmitFile(cacheAbsPath);
                return;
            }



            string filePath = path + name;

            string fileAbsPath = ServerUtility.MapPath(filePath);

            if (File.Exists(fileAbsPath))
            {

                var dynamicInfo = DynamicInfo.Get(base64);

                Image originalImage = Image.FromFile(fileAbsPath);
                Image outImg = null;



                if (dynamicInfo.Crop != null)
                {
                    outImg = ImageHelper.GetImageThumbnailCropHeight(originalImage, dynamicInfo.Crop.Width, dynamicInfo.Crop.Height);
                }

                if (dynamicInfo.Resize != null)
                {
                    var resize = dynamicInfo.Resize;
                    if (resize.Height > 0 && resize.Width > 0)
                    {
                        outImg = ImageHelper.GetImageThumbnail(originalImage, dynamicInfo.Resize.Width, dynamicInfo.Resize.Height);
                    }
                    else if (resize.Height > 0 && resize.Width == 0)
                    {
                        outImg = ImageHelper.GetImageThumbnailByHeight(originalImage, dynamicInfo.Resize.Height);

                    }
                    else if (resize.Height == 0 && resize.Width > 0)
                    {
                        outImg = ImageHelper.GetImageThumbnailByWidth(originalImage, dynamicInfo.Resize.Width);
                    }
                    else
                    {
                        outImg = originalImage;
                    }
                }


                if (dynamicInfo.WaterMark != null)
                {
                    if (outImg == null)
                    {
                        outImg = ImageHelper.WatermarkImage(originalImage, dynamicInfo.WaterMark);
                    }
                    else
                    {
                        outImg = ImageHelper.WatermarkImage(outImg, dynamicInfo.WaterMark);
                    }
                }





                string dirPath = Path.GetDirectoryName(cacheAbsPath);

                if (!Directory.Exists(dirPath))
                {
                    Directory.CreateDirectory(dirPath);
                }

                try
                {

                    if (outImg == null)
                    {
                        Response.StatusCode = 404;
                    }
                    else
                    {
                        outImg.Save(cacheAbsPath);
                        Response.TransmitFile(cacheAbsPath);
                    }

                }
                catch (Exception ex)
                {
                    Response.Write(cacheAbsPath);
                    Response.Write(ex.Message);

                }
                finally
                {
                    if (outImg != null)
                    {
                        outImg.Dispose();
                    }

                    if (originalImage != null)
                    {
                        originalImage.Dispose();
                    }

                }

                return;
            }
        }


        Response.StatusCode = 404;
        Response.End();
    }

    void echo_json(bool success, string json)
    {

        Response.ContentType = "application/x-javascript;charset=" + encodingName;

        string callback = Request["callback"] ?? string.Empty;

        StringBuilder jsonString = new StringBuilder();

        jsonString.Append("{");
        jsonString.Append("\"resp\":{\"success\":");
        jsonString.Append(success ? "1" : "0");
        jsonString.Append(json);
        jsonString.Append("}");
        jsonString.Append("}");

        if (!string.IsNullOrEmpty(callback))
        {
            Response.Write(callback.Replace("$data", jsonString.ToString()));
        }
        else
        {
            Response.Write(jsonString.ToString());
        }
    }

    void echo_xml(bool success, string xml)
    {
        Response.ContentType = "text/xml;charset=" + encodingName;

        Response.Write("<?xml version=\"1.0\" encoding=\"" + encodingName + "\"?>\r\n");
        Response.Write("<resp>\r\n");
        Response.Write("<success>");
        Response.Write(success ? "1" : "0");
        Response.Write("</success>");
        Response.Write("\r\n");
        Response.Write(xml);
        Response.Write("</resp>\r\n");


    }



    void upload(bool serverUpload)
    {
        if (isTrueSecurityKey)
        {
            HttpFileCollection files = Request.Files;

            if (files.Count >= 1)
            {

                HttpPostedFile file = files[0];

                DateTime today = DateTime.Today;

                string folder = serverUpload ? Request["folder"] : "/" + today.Year + "/" + today.Month + "/" + today.Day + "/";

                string absFolder = ServerUtility.MapPath(folder);

                if (!Directory.Exists(absFolder))
                {
                    Directory.CreateDirectory(absFolder);
                }

                string fileName = serverUpload ? Request["fileName"] : Guid.NewGuid().ToString();

                string fileExt = serverUpload ? Request["fileExt"] : Path.GetExtension(file.FileName);

                file.SaveAs(absFolder + @"\" + fileName + fileExt);


                if (!serverUpload)
                {
                    uploadOthersServers(file, folder, fileName, fileExt);
                }


                string link = ConfigSetting.Current.Domain + folder + fileName + fileExt;

                switch (format)
                {
                    case "xml":
                        echo_xml(true, "<link>" + link + "</link>");
                        break;

                    case "json":
                        echo_json(true, ",\"link\":\"" + link + "\"");
                        break;

                }


                return;

            }
        }




        switch (format)
        {
            case "xml":
                echo_xml(false, "<msg>upload failed</msg>");
                break;

            case "json":
                echo_json(false, ",\"msg\":\"upload failed\"");
                break;

        }

    }


    void upload_error(FileInfo xmlfile)
    {
        if (xmlfile.Exists)
        {
            Response.Write("File:" + xmlfile.FullName + "\r\n");

            XmlDocument doc = new XmlDocument();
            doc.Load(xmlfile.FullName);
            XmlNode serverNode = doc.SelectSingleNode("/Info/Server");

            XmlNode fileNode = doc.SelectSingleNode("/Info/File");


            string folder = fileNode.Attributes["Folder"].Value;
            string fileName = fileNode.Attributes["FileName"].Value;
            string fileExt = fileNode.Attributes["FileExt"].Value;

            string filePath = folder + fileName + fileExt;

            string absFilePath = ServerUtility.MapPath(filePath);

            if (serverNode != null && fileNode != null && File.Exists(absFilePath))
            {
                Server ser = new Server();

                ser.Name = serverNode.Attributes["Name"].Value;
                ser.SecurityKey = serverNode.Attributes["SecurityKey"].Value;
                ser.Uri = new Uri(serverNode.Attributes["Uri"].Value);

                byte[] data = File.ReadAllBytes(absFilePath);

                using (Task<bool> task = uploadServerAsync(ser, data, folder, fileName, fileExt))
                {

                    task.Wait();

                    if (task.Result)
                    {
                        Response.Write("Server:" + ser.Name + ",Uri:" + ser.Uri + " 【upload success】\r\n");
                        xmlfile.Delete();
                    }
                    else
                    {
                        Response.Write("Server:" + ser.Name + ",Uri:" + ser.Uri + " 【upload failed】\r\n");
                    }

                    task.Dispose();
                }


            }
        }
    }

    void upload_errors(DirectoryInfo dir)
    {

        if (dir.Exists)
        {
            Response.Write("Folder:" + dir.FullName + "\r\n");

            FileInfo[] fis = dir.GetFiles();

            for (int i = 0; i < fis.Length; i++)
            {
                upload_error(fis[i]);


            }

            DirectoryInfo[] dirs = dir.GetDirectories();
            for (int i = 0; i < dirs.Length; i++)
            {
                upload_errors(dirs[i]);
            }
        }
    }

    void upload_errors()
    {
        Response.Buffer = false;
        Response.ContentType = "text/plain;charset=" + encodingName;

        if (isTrueSecurityKey)
        {
            string logFolder = ConfigSetting.Current.Log;

            string absLogFolder = ServerUtility.MapPath(logFolder);

            DirectoryInfo dir = new DirectoryInfo(absLogFolder);

            upload_errors(dir);
        }
    }

    // 传输到其他备份服务器
    void uploadOthersServers(HttpPostedFile file, string folder, string fileName, string fileExt)
    {

        byte[] fileData = null;

        Stream inputStream = file.InputStream;

        if (inputStream != null)
        {
            long len = inputStream.Length;
            if (len > 0)
            {
                fileData = new byte[len];

                inputStream.Read(fileData, 0, (int)len);
            }
        }

        if (fileData == null)
        {
            return;
        }



        var servers = ConfigSetting.Current.Servers;
        foreach (var server in servers)
        {
            if (server.Name != ConfigSetting.Current.ServerName)
            {
                uploadServerAsync(server, fileData, folder, fileName, fileExt);
            }
        }
    }



    // 异步传输到其他备份服务器
    async Task<bool> uploadServerAsync(Server server, byte[] fileData, string folder, string fileName, string fileExt)
    {


        string uri = server.Uri.ToString() + "?action=serverupload&SecurityKey=" + server.SecurityKey + "&folder=" + folder + "&fileName=" + fileName + "&fileExt=" + fileExt;

        HttpPost.HttpUploadFile uploadfile = new HttpPost.HttpUploadFile();

        uploadfile.Name = "file";

        uploadfile.FileName = fileName + fileExt;

        uploadfile.Data = fileData;

        string msg = string.Empty;

        bool createErrorLog = true;

        try
        {

            byte[] receiveData = HttpPost.UploadFile(new Uri(uri), uploadfile);

            msg = encoding.GetString(receiveData);


            string xmlString = encoding.GetString(receiveData);

            if (!string.IsNullOrEmpty(xmlString))
            {

                XmlDocument doc = new XmlDocument();
                doc.LoadXml(xmlString);
                XmlNode node = doc.SelectSingleNode("/resp/success");
                if (node != null)
                {
                    string successNumber = node.InnerText;

                    int number = 0;
                    if (int.TryParse(successNumber, out number))
                    {
                        if (number == 1)
                        {
                            createErrorLog = false;
                            return true;
                        }
                    }
                }
            }

        }
        catch
        {

        }

        if (createErrorLog)
        {
            string logFolder = ConfigSetting.Current.Log + folder;

            string absLogFolder = ServerUtility.MapPath(logFolder);

            if (!Directory.Exists(absLogFolder))
            {
                Directory.CreateDirectory(absLogFolder);
            }

            string logFile = absLogFolder + server.Name + "_" + fileName + ".xml";

            if (File.Exists(logFile))
            {
                return false;
            }

            StringBuilder xmlString = new StringBuilder();

            xmlString.AppendLine("<?xml version=\"1.0\" encoding=\"" + encodingName + "\"?>");

            xmlString.AppendLine("<Info>");

            xmlString.AppendLine("<Server Name=\"" + server.Name + "\" Uri=\"" + server.Uri + "\" SecurityKey=\"" + server.SecurityKey + "\" />");

            xmlString.AppendLine("<File Folder=\"" + folder + "\" FileName=\"" + fileName + "\" FileExt=\"" + fileExt + "\" />");

            xmlString.AppendLine("<Msg><![CDATA[" + msg + "]]></Msg>");

            xmlString.AppendLine("</Info>");


            byte[] xmlData = encoding.GetBytes(xmlString.ToString());

            using (FileStream fs = File.Create(logFile))
            {

                fs.Write(xmlData, 0, xmlData.Length);
                fs.Close();
                fs.Dispose();
            }
        }


        return false;
    }


    void delete()
    {

    }

    public bool IsReusable
    {
        get
        {
            return false;
        }
    }
}





