namespace Wfrs.Server
{
  public class TicketItem

  {
    public string Id { get; set; }
    public string Title { get; set; }
    public string Description { get; set; }
    public string EventId { get; set; }
    public string ValidFrom { get; set; }
    public string ValidUntil { get; set; }
    public string Price { get; set; }
  }
}