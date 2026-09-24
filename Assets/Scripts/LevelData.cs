using UnityEngine;

[CreateAssetMenu(fileName = "Level", menuName = "Game/Level Data")]
public class LevelData : ScriptableObject
{
    public string levelName;
    [Range(0f, 1f)] public float corruption;
    public Color tint = Color.white;
    public AudioClip music;
}
