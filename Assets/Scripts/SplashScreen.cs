using System.Collections;
using UnityEngine;
using UnityEngine.SceneManagement;
using UnityEngine.InputSystem;

public class SplashScreen : MonoBehaviour
{
    [Header("Logos, shown one after another")]
    [SerializeField] private CanvasGroup[] logoGroups;
    [SerializeField] private float fadeInTime = 1f;
    [SerializeField] private float holdTime = 1.5f;
    [SerializeField] private float fadeOutTime = 1f;

    [Header("Next Scene")]
    [SerializeField] private string nextSceneName = "MainMenu";

    private void Start()
    {
        foreach (var group in logoGroups)
        {
            if (group != null) group.alpha = 0f;
        }
        StartCoroutine(PlaySplash());
    }

    private IEnumerator PlaySplash()
    {
        foreach (var group in logoGroups)
        {
            if (group == null) continue;
            yield return Fade(group, 0f, 1f, fadeInTime);
            yield return new WaitForSeconds(holdTime);
            yield return Fade(group, 1f, 0f, fadeOutTime);
        }
        SceneManager.LoadScene(nextSceneName);
    }

    private IEnumerator Fade(CanvasGroup group, float from, float to, float duration)
    {
        float t = 0f;
        while (t < duration)
        {
            t += Time.deltaTime;
            group.alpha = Mathf.Lerp(from, to, t / duration);
            yield return null;
        }
        group.alpha = to;
    }

    // Lets a player tap or click to skip straight to the next scene.
    private void Update()
    {
        bool skipPressed =
            (Keyboard.current != null && Keyboard.current.anyKey.wasPressedThisFrame) ||
            (Mouse.current != null && Mouse.current.leftButton.wasPressedThisFrame);

        if (skipPressed)
        {
            StopAllCoroutines();
            SceneManager.LoadScene(nextSceneName);
        }
    }
}