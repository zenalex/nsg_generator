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
    [HttpGet]
    public IHttpActionResult GetNews()
    {
      var user = AuthImplReal.GetUserSettingsByToken(Request);
      return Ok(controller.GetNews(user));
    }

    /// <summary>
    /// Get card
    /// </summary>
    [Route("GetCard")]
    [System.Web.Http.Authorize(Roles = UserRoles.User)]
    [HttpGet]
    public IHttpActionResult GetCard()
    {
      var user = AuthImplReal.GetUserSettingsByToken(Request);
      return Ok(controller.GetCard(user));
    }

    /// <summary>
    /// Get cities
    /// </summary>
    [Route("GetCity")]
    [System.Web.Http.Authorize]
    [HttpGet]
    public IHttpActionResult GetCity()
    {
      var user = AuthImplReal.GetUserSettingsByToken(Request);
      return Ok(controller.GetCity(user));
    }

    /// <summary>
    /// Get countries
    /// </summary>
    [Route("GetCountry")]
    [System.Web.Http.Authorize]
    [HttpGet]
    public IHttpActionResult GetCountry()
    {
      var user = AuthImplReal.GetUserSettingsByToken(Request);
      return Ok(controller.GetCountry(user));
    }

  }
}