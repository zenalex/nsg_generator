using System.Net.Http;
using System.Web.Http;
using Wfrs.Server;

namespace Wfrs.Server
{
  /// <summary>
  ///NsgDataItemInterface Controller
  /// </summary>
  [RoutePrefix("Api/Data")]
  public class DataController : ApiController
  {
    DataSource controller;
    public DataController()
    {
      #if (Real)
        controller = new Real_DataController();
      #else
        controller = new fake_DataController();
      #endif
    }
    /// <summary>
    /// Get news
    /// </summary>
    [Route("GetNews")]
    [System.Web.Http.Authorize]
    [HttpPost]
    public IHttpActionResult GetNews()
    {
      var user = AuthImplReal.GetUserSettingsByToken(Request);
      return Ok(controller.GetNews(user));
    }

  }
}