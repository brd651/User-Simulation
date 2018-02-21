#Import needed modules
Import-Module BitsTransfer

#Functions added here

#Screenshot function
Function Take-ScreenShot { 
    <#   
.SYNOPSIS   
    Used to take a screenshot of the desktop or the active window.  
.DESCRIPTION   
    Used to take a screenshot of the desktop or the active window and save to an image file if needed. 
.PARAMETER screen 
    Screenshot of the entire screen 
.PARAMETER activewindow 
    Screenshot of the active window 
.PARAMETER file 
    Name of the file to save as. Default is image.bmp 
.PARAMETER imagetype 
    Type of image being saved. Can use JPEG,BMP,PNG. Default is bitmap(bmp)   
.PARAMETER print 
    Sends the screenshot directly to your default printer       
.INPUTS 
.OUTPUTS     
.NOTES   
    Name: Take-ScreenShot 
    Author: Boe Prox 
    DateCreated: 07/25/2010      
.EXAMPLE   
    Take-ScreenShot -activewindow 
    Takes a screen shot of the active window         
.EXAMPLE   
    Take-ScreenShot -Screen 
    Takes a screenshot of the entire desktop 
.EXAMPLE   
    Take-ScreenShot -activewindow -file "C:\image.bmp" -imagetype bmp 
    Takes a screenshot of the active window and saves the file named image.bmp with the image being bitmap 
.EXAMPLE   
    Take-ScreenShot -screen -file "C:\image.png" -imagetype png     
    Takes a screenshot of the entire desktop and saves the file named image.png with the image being png 
.EXAMPLE   
    Take-ScreenShot -Screen -print 
    Takes a screenshot of the entire desktop and sends to a printer 
.EXAMPLE   
    Take-ScreenShot -ActiveWindow -print 
    Takes a screenshot of the active window and sends to a printer     
#>   
#Requires -Version 2 
        [cmdletbinding( 
                SupportsShouldProcess = $True, 
                DefaultParameterSetName = "screen", 
                ConfirmImpact = "low" 
        )] 
Param ( 
       [Parameter( 
            Mandatory = $False, 
            ParameterSetName = "screen", 
            ValueFromPipeline = $True)] 
            [switch]$screen, 
       [Parameter( 
            Mandatory = $False, 
            ParameterSetName = "window", 
            ValueFromPipeline = $False)] 
            [switch]$activewindow, 
       [Parameter( 
            Mandatory = $False, 
            ParameterSetName = "", 
            ValueFromPipeline = $False)] 
            [string]$file,  
       [Parameter( 
            Mandatory = $False, 
            ParameterSetName = "", 
            ValueFromPipeline = $False)] 
            [string] 
            [ValidateSet("bmp","jpeg","png")] 
            $imagetype = "bmp", 
       [Parameter( 
            Mandatory = $False, 
            ParameterSetName = "", 
            ValueFromPipeline = $False)] 
            [switch]$print                        
        
) 
# C# code 
$code = @' 
using System; 
using System.Runtime.InteropServices; 
using System.Drawing; 
using System.Drawing.Imaging; 
namespace ScreenShotDemo 
{ 
  /// <summary> 
  /// Provides functions to capture the entire screen, or a particular window, and save it to a file. 
  /// </summary> 
  public class ScreenCapture 
  { 
    /// <summary> 
    /// Creates an Image object containing a screen shot the active window 
    /// </summary> 
    /// <returns></returns> 
    public Image CaptureActiveWindow() 
    { 
      return CaptureWindow( User32.GetForegroundWindow() ); 
    } 
    /// <summary> 
    /// Creates an Image object containing a screen shot of the entire desktop 
    /// </summary> 
    /// <returns></returns> 
    public Image CaptureScreen() 
    { 
      return CaptureWindow( User32.GetDesktopWindow() ); 
    }     
    /// <summary> 
    /// Creates an Image object containing a screen shot of a specific window 
    /// </summary> 
    /// <param name="handle">The handle to the window. (In windows forms, this is obtained by the Handle property)</param> 
    /// <returns></returns> 
    private Image CaptureWindow(IntPtr handle) 
    { 
      // get te hDC of the target window 
      IntPtr hdcSrc = User32.GetWindowDC(handle); 
      // get the size 
      User32.RECT windowRect = new User32.RECT(); 
      User32.GetWindowRect(handle,ref windowRect); 
      int width = windowRect.right - windowRect.left; 
      int height = windowRect.bottom - windowRect.top; 
      // create a device context we can copy to 
      IntPtr hdcDest = GDI32.CreateCompatibleDC(hdcSrc); 
      // create a bitmap we can copy it to, 
      // using GetDeviceCaps to get the width/height 
      IntPtr hBitmap = GDI32.CreateCompatibleBitmap(hdcSrc,width,height); 
      // select the bitmap object 
      IntPtr hOld = GDI32.SelectObject(hdcDest,hBitmap); 
      // bitblt over 
      GDI32.BitBlt(hdcDest,0,0,width,height,hdcSrc,0,0,GDI32.SRCCOPY); 
      // restore selection 
      GDI32.SelectObject(hdcDest,hOld); 
      // clean up 
      GDI32.DeleteDC(hdcDest); 
      User32.ReleaseDC(handle,hdcSrc); 
      // get a .NET image object for it 
      Image img = Image.FromHbitmap(hBitmap); 
      // free up the Bitmap object 
      GDI32.DeleteObject(hBitmap); 
      return img; 
    } 
    /// <summary> 
    /// Captures a screen shot of the active window, and saves it to a file 
    /// </summary> 
    /// <param name="filename"></param> 
    /// <param name="format"></param> 
    public void CaptureActiveWindowToFile(string filename, ImageFormat format) 
    { 
      Image img = CaptureActiveWindow(); 
      img.Save(filename,format); 
    } 
    /// <summary> 
    /// Captures a screen shot of the entire desktop, and saves it to a file 
    /// </summary> 
    /// <param name="filename"></param> 
    /// <param name="format"></param> 
    public void CaptureScreenToFile(string filename, ImageFormat format) 
    { 
      Image img = CaptureScreen(); 
      img.Save(filename,format); 
    }     
    
    /// <summary> 
    /// Helper class containing Gdi32 API functions 
    /// </summary> 
    private class GDI32 
    { 
       
      public const int SRCCOPY = 0x00CC0020; // BitBlt dwRop parameter 
      [DllImport("gdi32.dll")] 
      public static extern bool BitBlt(IntPtr hObject,int nXDest,int nYDest, 
        int nWidth,int nHeight,IntPtr hObjectSource, 
        int nXSrc,int nYSrc,int dwRop); 
      [DllImport("gdi32.dll")] 
      public static extern IntPtr CreateCompatibleBitmap(IntPtr hDC,int nWidth, 
        int nHeight); 
      [DllImport("gdi32.dll")] 
      public static extern IntPtr CreateCompatibleDC(IntPtr hDC); 
      [DllImport("gdi32.dll")] 
      public static extern bool DeleteDC(IntPtr hDC); 
      [DllImport("gdi32.dll")] 
      public static extern bool DeleteObject(IntPtr hObject); 
      [DllImport("gdi32.dll")] 
      public static extern IntPtr SelectObject(IntPtr hDC,IntPtr hObject); 
    } 
 
    /// <summary> 
    /// Helper class containing User32 API functions 
    /// </summary> 
    private class User32 
    { 
      [StructLayout(LayoutKind.Sequential)] 
      public struct RECT 
      { 
        public int left; 
        public int top; 
        public int right; 
        public int bottom; 
      } 
      [DllImport("user32.dll")] 
      public static extern IntPtr GetDesktopWindow(); 
      [DllImport("user32.dll")] 
      public static extern IntPtr GetWindowDC(IntPtr hWnd); 
      [DllImport("user32.dll")] 
      public static extern IntPtr ReleaseDC(IntPtr hWnd,IntPtr hDC); 
      [DllImport("user32.dll")] 
      public static extern IntPtr GetWindowRect(IntPtr hWnd,ref RECT rect); 
      [DllImport("user32.dll")] 
      public static extern IntPtr GetForegroundWindow();       
    } 
  } 
} 
'@ 
#User Add-Type to import the code 
add-type $code -ReferencedAssemblies 'System.Windows.Forms','System.Drawing' 
#Create the object for the Function 
$capture = New-Object ScreenShotDemo.ScreenCapture 
 
#Take screenshot of the entire screen 
If ($Screen) { 
    Write-Verbose "Taking screenshot of entire desktop" 
    #Save to a file 
    If ($file) { 
        If ($file -eq "") { 
            $file = "$pwd\image.bmp" 
            } 
        Write-Verbose "Creating screen file: $file with imagetype of $imagetype" 
        $capture.CaptureScreenToFile($file,$imagetype) 
        } 
    ElseIf ($print) { 
        $img = $Capture.CaptureScreen() 
        $pd = New-Object System.Drawing.Printing.PrintDocument 
        $pd.Add_PrintPage({$_.Graphics.DrawImage(([System.Drawing.Image]$img), 0, 0)}) 
        $pd.Print() 
        }         
    Else { 
        $capture.CaptureScreen() 
        } 
    } 
#Take screenshot of the active window     
If ($ActiveWindow) { 
    Write-Verbose "Taking screenshot of the active window" 
    #Save to a file 
    If ($file) { 
        If ($file -eq "") { 
            $file = "$pwd\image.bmp" 
            } 
        Write-Verbose "Creating activewindow file: $file with imagetype of $imagetype" 
        $capture.CaptureActiveWindowToFile($file,$imagetype) 
        } 
    ElseIf ($print) { 
        $img = $Capture.CaptureActiveWindow() 
        $pd = New-Object System.Drawing.Printing.PrintDocument 
        $pd.Add_PrintPage({$_.Graphics.DrawImage(([System.Drawing.Image]$img), 0, 0)}) 
        $pd.Print() 
        }         
    Else { 
        $capture.CaptureActiveWindow() 
        }     
    }      
}    


#Change Directory for file transfers
chdir C:\Users\Public\Downloads

#define arrays to be used through to be loaded in groups of 10
$array1 = @("youtube.com","google.com", "cnn.com","thinkgeek.com","linkedin.com","sonicwall.com","sourceforge.com","live.com","huffingtonpost.com","walmart.com")
$array2 = @("bing.com","yahoo.com","bbc.co.uk","geek.com","reddit.com","apple.com","yahoo.com","blogspot.com","imdb.com","about.com")
$array3 = @("nfl.com","usatoday.com","foxnews.com","newegg.com","target.com","nba.com","bestbuy.com","gizmodo.com","stackoverflow.com","godaddy.com")
$array4 = @("southwest.com","drudgereport.com","lifehacker.com","indeed.com","ign.com","groupon.com","cbssports.com","reuters.com","yelp.com","imgur.com")
$array5 = @("att.com","kickstart.com","nasa.gov","change.org","tigerdirect.com","sears.com","weebly.com","nj.com","macys.com","amazon.com")
$array6 = @("tweetdeck.twitter.com", "finance.yahoo.com/most-active","imgur.com","pinterest.com","weather.com","dailymotion.com","bloomberg.com/businessweek","howstuffworks.com","bodybuilding.com","nascar.com","mlb.com","hp.com/country/us","marketwatch.com","cracked.com","macrumors.com","amc.com","victoriassecret.com","sephora.com","ubuntu.com","makeuseof.com","gamespot.com","geniuskitchen.com")

#defining Array for all the page Arrays to be used in the nested foreach loop
$PageArrays = @($array1,$array2,$array3,$array4,$array5,$array6)

#DEFINING GLOBAL VARIABLES

#Page Load Sleep
$PLS = Start-Sleep -s 5
#After Page Load Speed test
$APLS = Start-Sleep -s 15

#Open Internet Explorer with testmy.net to get before Mbps and once every 10 mins after, cannot do it faster because of site restrictions
Start-Process iexplore.exe @('-private',"http://testmy.net/auto?extraID=A&schType=&st=1&r_time=0.1666667&xtimes=5&minDFS=&minUFS=")

#Sleep for 3 Mins to give it time to run when in the middle of testing
Start-Sleep -s 180

#Opens Streaming sites in Google Chrome to have a continous flow of traffic

#ytroulette.com is a site that pulls youtubes videos randomly and will continously play them
#Opening Multiple of ytroulette to get multiple videos running at the sametime
Foreach ($_ in 1..10){
    $i++
    Start-Process chrome.exe @('-incognito',"https://ytroulette.com")
    $PLS
}
#This is One of MSN's video feeds
Start-Process chrome.exe @('-incognito',"https://www.msn.com/en-us/video/animals")
$PLS
#This is CNN's Video Feed
Start-Process chrome.exe @('-incognito',"https://www.cnn.com/videos")
$PLS
#Twitch.tv is a Live Streaming Gaming Website, Landing Page Always has something on it
Start-Process chrome.exe @('-incognito',"https://twitch.tv")
$PLS
#thepetcollective is a live Stream that is always up and running 24/7
Start-Process chrome.exe @('-incognito',"https://go.twitch.tv/thepetcollective")
$PLS
#Pandora is an Online Streaming Radio Startion (Station = Top Dance Music)
Start-Process chrome.exe @('-incognito',"https://www.pandora.com/station/play/3771788151533524254")
$PLS
#

#Each one of the below foreach statements will open up the defined array with 10 seconds inbetween page loads
#Then at the end it waits 30 seconds then closes the session before starting the next Array
#This is all done in Incognito to ensure loading and maxium traffic flow

foreach ($a in $PageArrays){
    :next foreach ($element in $a) {
        Start-Process firefox.exe -ArgumentList @('-private-window',"https://$element")
        $PLS
    }

        $APLS
        Start-Process firefox.exe -ArgumentList @('-new-window -private-window',"https://fast.com/")
        $APLS
        Take-ScreenShot -screen -file "C:\Users\Public\Downloads\Screenshots\image6.png" -imagetype png
        Start-Process firefox.exe -ArgumentList @('-private-window')
}

Stop-Process -processname Firefox
Stop-Process -processname chrome