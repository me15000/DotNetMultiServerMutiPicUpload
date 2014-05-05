using System;
using System.Drawing;
using System.Drawing.Drawing2D;
using System.Drawing.Imaging;
using System.Web;

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


