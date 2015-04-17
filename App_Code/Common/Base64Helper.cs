using System;



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



