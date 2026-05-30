using System.Collections.Concurrent;

namespace MarketplaceApi.Services;

public class ChatConnectionManager
{
    // UserId -> active SignalR connection IDs for all devices/tabs.
    private readonly ConcurrentDictionary<int, ConcurrentDictionary<string, byte>> _userConnections = new();

    public bool ConnectUser(int userId, string connectionId)
    {
        var connections = _userConnections.GetOrAdd(userId, _ => new ConcurrentDictionary<string, byte>());
        var wasOffline = connections.IsEmpty;
        connections.TryAdd(connectionId, 0);
        return wasOffline;
    }

    public bool DisconnectUser(int userId, string connectionId)
    {
        if (!_userConnections.TryGetValue(userId, out var connections))
        {
            return false;
        }

        connections.TryRemove(connectionId, out _);
        if (!connections.IsEmpty)
        {
            return false;
        }

        _userConnections.TryRemove(userId, out _);
        return true;
    }

    public bool IsUserOnline(int userId)
    {
        return _userConnections.TryGetValue(userId, out var connections) && !connections.IsEmpty;
    }

    public IReadOnlyCollection<int> OnlineUserIds => _userConnections.Keys.ToArray();
}
