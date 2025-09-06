public interface IBorrowerSelector  {

    List<Contact> selectByIds(Set<Id> idSet);
    Contact selectById(Id recordId);
    List<Contact> selectAll();
    Map<Id, Contact> getBorrowerMap(Set<Id> idSet);
}