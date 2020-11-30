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

    /// <summary>
    /// Get events
    /// </summary>
    [Route("GetEvent")]
    [System.Web.Http.Authorize]
    [HttpGet]
    public IHttpActionResult GetEvent()
    {
      var user = AuthImplReal.GetUserSettingsByToken(Request);
      return Ok(controller.GetEvent(user));
    }

    /// <summary>
    /// Get league
    /// </summary>
    [Route("GetLeague")]
    [System.Web.Http.Authorize]
    [HttpGet]
    public IHttpActionResult GetLeague()
    {
      var user = AuthImplReal.GetUserSettingsByToken(Request);
      return Ok(controller.GetLeague(user));
    }

    /// <summary>
    /// Get order
    /// </summary>
    [Route("GetOrder")]
    [System.Web.Http.Authorize]
    [HttpGet]
    public IHttpActionResult GetOrder()
    {
      var user = AuthImplReal.GetUserSettingsByToken(Request);
      return Ok(controller.GetOrder(user));
    }

    /// <summary>
    /// Get team
    /// </summary>
    [Route("GetTeam")]
    [System.Web.Http.Authorize]
    [HttpGet]
    public IHttpActionResult GetTeam()
    {
      var user = AuthImplReal.GetUserSettingsByToken(Request);
      return Ok(controller.GetTeam(user));
    }

    /// <summary>
    /// Get ticket
    /// </summary>
    [Route("GetTicket")]
    [System.Web.Http.Authorize]
    [HttpGet]
    public IHttpActionResult GetTicket()
    {
      var user = AuthImplReal.GetUserSettingsByToken(Request);
      return Ok(controller.GetTicket(user));
    }

    /// <summary>
    /// Get user settings
    /// </summary>
    [Route("GetUserSettings")]
    [System.Web.Http.Authorize]
    [HttpGet]
    public IHttpActionResult GetUserSettings()
    {
      var user = AuthImplReal.GetUserSettingsByToken(Request);
      return Ok(controller.GetUserSettings(user));
    }

  }
}