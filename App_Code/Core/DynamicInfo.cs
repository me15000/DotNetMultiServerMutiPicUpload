
using System.Text.RegularExpressions;
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
            Match m = RegWaterMarkInfo.Match(info);

            if (m.Success)
            {
                string pinfoString = m.Groups["p"].Value;

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

                    entity.waterMarkInfo = inf;

                }

            }
        }

        return entity;
    }
}

