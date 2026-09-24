using System;
using UnityEngine;

public class GameManager : MonoBehaviour
{
    public static GameManager Instance { get; private set; }

    [SerializeField] private LevelData[] levels;
    [SerializeField] private int startLevel = 0;

    public LevelData CurrentLevel { get; private set; }
    public int CurrentIndex { get; private set; }

    public event Action<LevelData> LevelChanged;

    private void Awake()
    {
        if (Instance != null && Instance != this)
        {
            Destroy(gameObject);
            return;
        }
        Instance = this;
    }

    private void Start()
    {
        SetLevel(startLevel);
    }

    public void SetLevel(int index)
    {
        if (levels == null || levels.Length == 0) return;
        CurrentIndex = Mathf.Clamp(index, 0, levels.Length - 1);
        CurrentLevel = levels[CurrentIndex];
        LevelChanged?.Invoke(CurrentLevel);
    }

    public void NextLevel()
    {
        SetLevel(CurrentIndex + 1);
    }

    private void Update()
    {
        // Debug only. Press N to advance a level.
        if (UnityEngine.InputSystem.Keyboard.current != null &&
            UnityEngine.InputSystem.Keyboard.current.nKey.wasPressedThisFrame)
        {
            NextLevel();
        }
    }
}
