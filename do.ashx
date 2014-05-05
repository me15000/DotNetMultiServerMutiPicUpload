<%@ WebHandler Language="C#" Class="DoHandler" %>

using System;
using System.Configuration;
using System.Collections.Generic;
using System.Collections.Specialized;
using System.Web;
using System.Xml;
using System.Xml.Serialization;
using System.IO;
using System.Net;
using System.Net.Sockets;
using System.Text;
using System.Text.RegularExpressions;

using System.Threading.Tasks;


using System.Drawing;
using System.Drawing.Drawing2D;
using System.Drawing.Imaging;


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



public class ConfigSetting
{

    public ConfigSetting()
    {
        string serversConfigPath = ConfigurationManager.AppSettings["Servers"];

        string absServersConfigPath = HttpContext.Current.Server.MapPath(serversConfigPath);

        XmlDocument doc = new XmlDocument();

        doc.Load(absServersConfigPath);

        var nodes = doc.SelectNodes("/Servers/Server");

        List<Server> Servers = new List<Server>();

        foreach (XmlNode node in nodes)
        {
            Server ser = new Server();

            ser.Uri = new Uri(node.Attributes["Uri"].Value);

            ser.SecurityKey = node.Attributes["SecurityKey"].Value;

            ser.Name = node.Attributes["Name"].Value;

            Servers.Add(ser);
        }

        servers = Servers;

    }




    System.Collections.Generic.List<Server> servers;

    static ConfigSetting current = null;

    public static ConfigSetting Current
    {
        get
        {
            if (current == null)
            {
                current = new ConfigSetting();
            }

            return current;
        }
    }

    public System.Collections.Generic.List<Server> Servers
    {
        get { return servers; }
    }

    public string ServerName
    {
        get
        {
            return ConfigurationManager.AppSettings["ServerName"];
        }
    }


    public string SecurityKey
    {
        get
        {
            return ConfigurationManager.AppSettings["SecurityKey"];
        }
    }

    public string Log
    {
        get
        {
            return ConfigurationManager.AppSettings["Log"];
        }
    }

    public string Domain
    {
        get
        {
            return ConfigurationManager.AppSettings["Domain"];
        }
    }

    public string CachePath
    {
        get
        {
            return ConfigurationManager.AppSettings["CachePath"];
        }
    }

    public string WaterMarkPath
    {
        get
        {
            return ConfigurationManager.AppSettings["WaterMarkPath"];
        }
    }

}



public struct Server
{
    public Uri Uri { get; set; }

    public string SecurityKey { get; set; }

    public string Name { get; set; }

}







public static class HttpPost
{

    public static byte[] UploadFile(Uri uri, HttpUploadFile file)
    {

        HttpPost.HttpUploadFile[] files = new HttpPost.HttpUploadFile[] { file };

        return UploadFiles(uri, files, null);

    }

    public static byte[] UploadFile(Uri uri, HttpUploadFile file, NameValueCollection values)
    {

        HttpPost.HttpUploadFile[] files = new HttpPost.HttpUploadFile[] { file };

        return UploadFiles(uri, files, values);

    }


    public static byte[] UploadFiles(Uri uri, HttpUploadFile[] files, NameValueCollection values)
    {
        string boundary = "----------------------------" + DateTime.Now.Ticks.ToString("x");
        HttpWebRequest request = (HttpWebRequest)WebRequest.Create(uri);
        request.ContentType = "multipart/form-data; boundary=" + boundary;
        request.Method = "POST";
        request.KeepAlive = true;
        request.Credentials = CredentialCache.DefaultCredentials;


        Stream stream = new MemoryStream();

        byte[] line = Encoding.ASCII.GetBytes("\r\n--" + boundary + "\r\n");


        if (values != null)
        {
            if (values.Count > 0)
            {
                string format = "\r\n--" + boundary + "\r\nContent-Disposition: form-data; name=\"{0}\";\r\n\r\n{1}";
                foreach (string key in values.Keys)
                {
                    string s = string.Format(format, key, values[key]);
                    byte[] data = Encoding.UTF8.GetBytes(s);
                    stream.Write(data, 0, data.Length);
                }

            }
        }

        stream.Write(line, 0, line.Length);

        if (files != null)
        {
            if (files.Length > 0)
            {
                string format = "Content-Disposition: form-data; name=\"{0}\"; filename=\"{1}\"\r\n Content-Type: application/octet-stream\r\n\r\n";
                foreach (HttpUploadFile file in files)
                {
                    string s = string.Format(format, file.Name, file.FileName);
                    byte[] data = Encoding.UTF8.GetBytes(s);
                    stream.Write(data, 0, data.Length);



                    stream.Write(file.Data, 0, file.Data.Length);
                    stream.Write(line, 0, line.Length);
                }
            }
        }


        request.ContentLength = stream.Length;


        Stream requestStream = request.GetRequestStream();
        stream.Position = 0L;

        stream.CopyTo(requestStream);
        requestStream.Close();


        using (var response = request.GetResponse())
        using (var responseStream = response.GetResponseStream())
        using (var mstream = new MemoryStream())
        {
            responseStream.CopyTo(mstream);
            return mstream.ToArray();
        }
    }






    public class HttpUploadFile
    {
        public HttpUploadFile()
        {
            ContentType = "application/octet-stream";
        }
        public string Name { get; set; }
        public string FileName { get; set; }
        public string ContentType { get; set; }
        public byte[] Data { get; set; }
    }
}


public static class Base64Helper
{

    public static bool TryParseBase64(string base64, out string str)
    {
        str = null;
        try
        {
            byte[] bytes = Convert.FromBase64String(base64);
            str = System.Text.Encoding.ASCII.GetString(bytes);
            return true;
        }
        catch
        {
            return false;
        }
    }


    public static string DecodeBase64(string base64)
    {
        string str = null;

        bool succ = TryParseBase64(base64, out str);

        if (!succ)
        {
            return null;
        }
        else
        {
            return str;
        }
    }


    public static string EncodeBase64(string str)
    {
        return Convert.ToBase64String(System.Text.Encoding.ASCII.GetBytes(str));
    }
}



public static class ImageHelper
{
    public static Image GetImageThumbnailByHeight(Image imgPhoto, int height)
    {
        decimal nPercent = (decimal)imgPhoto.Height / (decimal)height;

        if (nPercent > 1)
        {
            return GetImageThumbnail(imgPhoto, Convert.ToInt32(Math.Round(imgPhoto.Width / nPercent, 0)), height);
        }
        else
        {
            return imgPhoto;
        }

    }


    public static Image GetImageThumbnailByWidth(Image imgPhoto, int width)
    {
        decimal nPercent = (decimal)imgPhoto.Width / (decimal)width;

        if (nPercent > 1)
        {
            return GetImageThumbnail(imgPhoto, width, Convert.ToInt32(Math.Round(imgPhoto.Height / nPercent, 0)));
        }
        else
        {
            return imgPhoto;
        }
    }

    /// <summary>
    /// 缩放并且根据高度裁切图片
    /// </summary>
    /// <param name="originalImage"></param>
    /// <param name="width"></param>
    /// <param name="height"></param>
    /// <returns></returns>
    public static Image GetImageThumbnailCropHeight(Image originalImage, int width, int height)
    {

        Image imgPhoto = GetImageThumbnailByWidth(originalImage, width);

        if (imgPhoto.Height > height)
        {
            Bitmap image = new Bitmap(imgPhoto.Width, height, PixelFormat.Format24bppRgb);
            Graphics graphics = Graphics.FromImage(image);
            graphics.InterpolationMode = InterpolationMode.Default;
            graphics.SmoothingMode = System.Drawing.Drawing2D.SmoothingMode.HighQuality;
            graphics.DrawImage(imgPhoto, new Rectangle(0, 0, imgPhoto.Width, height), new Rectangle(0, 0, imgPhoto.Width, height), GraphicsUnit.Pixel);
            graphics.Dispose();
            imgPhoto.Dispose();

            return image;
        }
        else
        {
            return imgPhoto;
        }
    }

    public static Image GetImageThumbnail(Image imgPhoto, int width, int height)
    {
        decimal nPercent = 1;
        decimal wPercent = (decimal)imgPhoto.Width / (decimal)width;
        decimal hPercent = (decimal)imgPhoto.Height / (decimal)height;


        if (imgPhoto.Width <= width && imgPhoto.Height <= height)
        {
            return imgPhoto;
        }
        else
        {
            nPercent = wPercent > hPercent ? wPercent : hPercent;
        }

        int w, h;

        w = Convert.ToInt32(Math.Round(imgPhoto.Width / nPercent, 0));
        h = Convert.ToInt32(Math.Round(imgPhoto.Height / nPercent, 0));




        try
        {
            Bitmap image = new Bitmap(w, h, PixelFormat.Format24bppRgb);
            Graphics graphics = Graphics.FromImage(image);
            graphics.InterpolationMode = InterpolationMode.Default;
            graphics.SmoothingMode = System.Drawing.Drawing2D.SmoothingMode.HighQuality;
            graphics.DrawImage(imgPhoto, new Rectangle(0, 0, w, h), new Rectangle(0, 0, imgPhoto.Width, imgPhoto.Height), GraphicsUnit.Pixel);
            graphics.Dispose();

            return image;
        }
        catch
        {
            return null;
        }
    }


    public static Image WatermarkImage(Image originalImg, WaterMarkInfo wmi)
    {
        Bitmap image = new Bitmap(originalImg.Width, originalImg.Height, PixelFormat.Format32bppArgb);
        using (Graphics graphics = Graphics.FromImage(image))
        {



            string wmAbsPath = HttpContext.Current.Server.MapPath(ConfigSetting.Current.WaterMarkPath + "/" + wmi.WaterMark);


            Image waterImg = Image.FromFile(wmAbsPath);

            graphics.SmoothingMode = System.Drawing.Drawing2D.SmoothingMode.HighQuality;
            graphics.InterpolationMode = InterpolationMode.Default;
            graphics.DrawImage(originalImg, new Rectangle(0, 0, originalImg.Width, originalImg.Height), 0, 0, originalImg.Width, originalImg.Height, GraphicsUnit.Pixel);


            Rectangle destRect = new Rectangle
            {
                Height = waterImg.Height,
                Width = waterImg.Width
            };
            if (wmi.Top.HasValue)
            {
                destRect.Y = wmi.Top.Value;
            }
            if (wmi.Right.HasValue)
            {
                destRect.X = (originalImg.Width - waterImg.Width) - wmi.Right.Value;
            }
            if (wmi.Bottom.HasValue)
            {
                destRect.Y = (originalImg.Height - waterImg.Height) - wmi.Bottom.Value;
            }
            if (wmi.Left.HasValue)
            {
                destRect.X = wmi.Left.Value;
            }
            graphics.DrawImage(waterImg, destRect, 0, 0, waterImg.Width, waterImg.Height, GraphicsUnit.Pixel);
            waterImg.Dispose();
        }
        return image;
    }



}


public class WaterMarkInfo
{
    public int? Left { get; set; }
    public int? Right { get; set; }
    public int? Top { get; set; }
    public int? Bottom { get; set; }
    public string WaterMark { get; set; }
}


public class ResizeInfo
{
    public int Width { get; set; }
    public int Height { get; set; }
}

public class CropInfo
{
    public int Width { get; set; }
    public int Height { get; set; }
}


public class DynamicInfo
{
    WaterMarkInfo waterMarkInfo = null;

    public WaterMarkInfo WaterMark
    {
        get { return waterMarkInfo; }
        set { waterMarkInfo = value; }
    }

    ResizeInfo resizeInfo = null;
    public ResizeInfo Resize
    {
        get { return resizeInfo; }
        set { resizeInfo = value; }
    }

    CropInfo cropInfo = null;
    public CropInfo Crop
    {
        get { return cropInfo; }
        set { cropInfo = value; }
    }


    //裁切参数
    static Regex RegCropInfo = new Regex(@"\((?<w>\d*)_(?<h>\d*)\)");

    //缩放参数
    static Regex RegResizeInfo = new Regex(@"\((?<w>\d*)x(?<h>\d*)\)");

    //水印参数
    static Regex RegWaterMarkInfo = new Regex(@"\[(?<p>.+?)\]");

    public static DynamicInfo Get(string base64)
    {
        string info = Base64Helper.DecodeBase64(base64);

        DynamicInfo entity = new DynamicInfo();


        if (true)
        {
            Match m = RegResizeInfo.Match(info);

            if (m.Success)
            {

                ResizeInfo inf = new ResizeInfo();

                string w = m.Groups["w"].Value;
                string h = m.Groups["h"].Value;

                int wInt, hInt;

                bool wB = int.TryParse(w, out wInt), hB = int.TryParse(h, out hInt);

                if (wB)
                {
                    inf.Width = wInt;
                }

                if (hB)
                {
                    inf.Height = hInt;
                }

                entity.Resize = inf;
            }
        }



        if (true)
        {

            Match m = RegCropInfo.Match(info);

            if (m.Success)
            {
                CropInfo inf = new CropInfo();

                string w = m.Groups["w"].Value;
                string h = m.Groups["h"].Value;

                int wInt, hInt;
                bool wB = int.TryParse(w, out wInt), hB = int.TryParse(h, out hInt);

                if (wB)
                {
                    inf.Width = wInt;
                }

                if (hB)
                {
                    inf.Height = hInt;
                }

                entity.Crop = inf;

            }
        }


        if (true)
        {
            string pinfoString = RegWaterMarkInfo.Match(info).Groups["p"].Value;


            string[] pinfos = pinfoString.Split(',');

            if (pinfos.Length > 0)
            {

                WaterMarkInfo inf = new WaterMarkInfo();

                for (int i = 0; i < pinfos.Length; i++)
                {
                    string[] arr = pinfos[i].Split(':');

                    if (arr.Length == 2)
                    {
                        switch (arr[0])
                        {
                            case "wm":
                                inf.WaterMark = arr[1];
                                break;
                            case "t":
                                inf.Top = int.Parse(arr[1]);
                                break;
                            case "r":
                                inf.Right = int.Parse(arr[1]);
                                break;
                            case "b":
                                inf.Bottom = int.Parse(arr[1]);
                                break;
                            case "l":
                                inf.Left = int.Parse(arr[1]);
                                break;
                        }
                    }
                }

            }
        }

        return entity;
    }
}


