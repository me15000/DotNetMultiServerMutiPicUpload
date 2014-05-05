using System;
using System.Collections.Generic;
using System.Configuration;
using System.Web;
using System.Xml;



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


