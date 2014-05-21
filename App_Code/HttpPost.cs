using System;
using System.Collections.Specialized;
using System.IO;
using System.Net;
using System.Text;



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
                string format = "Content-Disposition: form-data; name=\"{0}\"; filename=\"{1}\";\r\n Content-Type: application/octet-stream\r\n\r\n";
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
