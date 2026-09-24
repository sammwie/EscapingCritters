using System;
using UnityEngine;

[Serializable]
public class PlayerProfile
{
    private const string SaveKey = "player_profile";

    public string playerName = "Player";
    public int hairStyle;
    public int skinIndex;
    public int hairColorIndex;
    public int outfitColorIndex;

    private static PlayerProfile current;

    public static PlayerProfile Current
    {
        get
        {
            if (current == null) current = Load();
            return current;
        }
    }

    public static void Save()
    {
        PlayerPrefs.SetString(SaveKey, JsonUtility.ToJson(Current));
        PlayerPrefs.Save();
    }

    private static PlayerProfile Load()
    {
        if (PlayerPrefs.HasKey(SaveKey))
        {
            return JsonUtility.FromJson<PlayerProfile>(PlayerPrefs.GetString(SaveKey));
        }
        return new PlayerProfile();
    }
}
