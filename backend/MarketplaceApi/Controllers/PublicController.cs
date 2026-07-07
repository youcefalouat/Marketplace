using Microsoft.AspNetCore.Mvc;
using Microsoft.Extensions.Caching.Memory;
using MarketplaceApi.DTOs;
using MarketplaceApi.Infrastructure;

namespace MarketplaceApi.Controllers;

[ApiController]
[Route("api/[controller]")]
public class PublicController : ControllerBase
{
    private readonly IMemoryCache _cache;

    public PublicController(IMemoryCache cache) => _cache = cache;

    // ─── GET /api/public/terms ───

    [HttpGet("terms")]
    public IActionResult GetTerms()
    {
        const string cacheKey = "legal_terms_v1";
        if (_cache.TryGetValue(cacheKey, out LegalDocumentResponseDto? cached))
            return Ok(cached);

        var document = new LegalDocumentResponseDto
        {
            Title = "Conditions Générales d'Utilisation",
            Version = "1.0",
            LastUpdated = LegalDocumentStore.TermsUpdatedAt.ToString("yyyy-MM-dd"),
            Language = "fr",
            Content = LegalDocumentStore.TermsHtml
        };

        _cache.Set(cacheKey, document, TimeSpan.FromHours(24));
        return Ok(document);
    }

    // ─── GET /api/public/legal/terms ───

    [HttpGet("legal/terms")]
    public IActionResult GetTermsHtml()
    {
        return Content(LegalDocumentStore.TermsHtml, "text/html; charset=utf-8");
    }

    // ─── GET /terms and /legal/terms ───

    [HttpGet]
    [Route("/terms")]
    [Route("/legal/terms")]
    public IActionResult GetTermsDirect()
    {
        return Content(LegalDocumentStore.TermsHtml, "text/html; charset=utf-8");
    }

    // ─── GET /privacy and /legal/privacy ───

    [HttpGet]
    [Route("/privacy")]
    [Route("/legal/privacy")]
    public IActionResult GetPrivacyDirect()
    {
        var content = new LegalContentDto
        {
            TitleFr = "Politique de confidentialité",
            TitleAr = "سياسة الخصوصية",
            UpdatedAt = LegalDocumentStore.TermsUpdatedAt,
            ContentFr = """
                ## 1. Collecte des données

                Nous collectons les informations que vous nous fournissez lors de l'inscription : nom, email, numéro de téléphone, wilaya et commune. Nous collectons également des données d'utilisation de l'application de manière anonyme.

                ## 2. Utilisation des données

                Vos données sont utilisées pour :

                - Gérer votre compte et vos annonces ;
                - Vous envoyer des notifications relatives à vos annonces et messages ;
                - Améliorer nos services.

                ## 3. Partage des données

                Nous ne vendons pas vos données personnelles. Vos coordonnées ne sont partagées qu'avec les utilisateurs avec qui vous choisissez de communiquer via la plateforme.

                ## 4. Sécurité

                Nous prenons des mesures raisonnables pour protéger vos données contre tout accès non autorisé, notamment le chiffrement des mots de passe et des communications.

                ## 5. Conservation des données

                Vos données sont conservées tant que votre compte est actif. Vous pouvez demander la suppression de votre compte et de vos données associées depuis cette page ou depuis votre profil.

                ## 6. Vos droits

                Vous disposez d'un droit d'accès, de rectification et de suppression de vos données personnelles. Pour exercer ces droits, contactez-nous.

                ## 7. Contact

                Pour toute question relative à cette politique, vous pouvez nous contacter à support@marketplace.com.
                """,
            ContentAr = """
                ## 1. جمع البيانات

                نجمع المعلومات التي تقدمها عند التسجيل: الاسم، البريد الإلكتروني، رقم الهاتف، الولاية والبلدية. كما نجمع بيانات استخدام التطبيق بشكل مجهول.

                ## 2. استخدام البيانات

                تُستخدم بياناتك من أجل:

                - إدارة حسابك وإعلاناتك؛
                - إرسال إشعارات تتعلق بإعلاناتك ورسائلك؛
                - تحسين خدماتنا.

                ## 3. مشاركة البيانات

                لا نبيع بياناتك الشخصية. لا تُشارك معلومات الاتصال الخاصة بك إلا مع المستخدمين الذين تختار التواصل معهم عبر المنصة.

                ## 4. الأمان

                نتخذ تدابير معقولة لحماية بياناتك من الوصول غير المصرح به، بما في ذلك تشفير كلمات المرور والاتصالات.

                ## 5. الاحتفاظ بالبيانات

                يتم الاحتفاظ ببياناتك طالما حسابك نشط. يمكنك طلب حذف حسابك والبيانات المرتبطة به من هذه الصفحة أو من ملفك الشخصي.

                ## 6. حقوقك

                لديك حق الوصول إلى بياناتك الشخصية وتصحيحها وحذفها. للاستفادة من هذه الحقوق، تواصل معنا.

                ## 7. التواصل

                لأي استفسار يتعلق بهذه السياسة، يمكنك التواصل معنا على support@marketplace.com.
                """
        };

        return Content(content.ContentFr, "text/html; charset=utf-8");
    }

    // ─── GET /api/public/privacy ───

    [HttpGet("privacy")]
    public IActionResult GetPrivacy()
    {
        if (_cache.TryGetValue("legal_privacy", out LegalContentDto? cached))
            return Ok(cached);

        var content = new LegalContentDto
        {
            TitleFr = "Politique de confidentialité",
            TitleAr = "سياسة الخصوصية",
            UpdatedAt = LegalDocumentStore.TermsUpdatedAt,
            ContentFr = """
                ## 1. Collecte des données

                Nous collectons les informations que vous nous fournissez lors de l'inscription : nom, email, numéro de téléphone, wilaya et commune. Nous collectons également des données d'utilisation de l'application de manière anonyme.

                ## 2. Utilisation des données

                Vos données sont utilisées pour :

                - Gérer votre compte et vos annonces ;
                - Vous envoyer des notifications relatives à vos annonces et messages ;
                - Améliorer nos services.

                ## 3. Partage des données

                Nous ne vendons pas vos données personnelles. Vos coordonnées ne sont partagées qu'avec les utilisateurs avec qui vous choisissez de communiquer via la plateforme.

                ## 4. Sécurité

                Nous prenons des mesures raisonnables pour protéger vos données contre tout accès non autorisé, notamment le chiffrement des mots de passe et des communications.

                ## 5. Conservation des données

                Vos données sont conservées tant que votre compte est actif. Vous pouvez demander la suppression de votre compte et de vos données associées depuis votre profil, dans la section Compte.

                ## 6. Vos droits

                Vous disposez d'un droit d'accès, de rectification et de suppression de vos données personnelles. Pour exercer ces droits, contactez-nous.

                ## 7. Contact

                Pour toute question relative à cette politique, vous pouvez nous contacter via l'application.
                """,
            ContentAr = """
                ## 1. جمع البيانات

                نجمع المعلومات التي تقدمها عند التسجيل: الاسم، البريد الإلكتروني، رقم الهاتف، الولاية والبلدية. كما نجمع بيانات استخدام التطبيق بشكل مجهول.

                ## 2. استخدام البيانات

                تُستخدم بياناتك من أجل:

                - إدارة حسابك وإعلاناتك؛
                - إرسال إشعارات تتعلق بإعلاناتك ورسائلك؛
                - تحسين خدماتنا.

                ## 3. مشاركة البيانات

                لا نبيع بياناتك الشخصية. لا تُشارك معلومات الاتصال الخاصة بك إلا مع المستخدمين الذين تختار التواصل معهم عبر المنصة.

                ## 4. الأمان

                نتخذ تدابير معقولة لحماية بياناتك من الوصول غير المصرح به، بما في ذلك تشفير كلمات المرور والاتصالات.

                ## 5. الاحتفاظ بالبيانات

                يتم الاحتفاظ ببياناتك طالما حسابك نشط. يمكنك طلب حذف حسابك والبيانات المرتبطة به من ملفك الشخصي، عبر قسم الحساب.

                ## 6. حقوقك

                لديك حق الوصول إلى بياناتك الشخصية وتصحيحها وحذفها. للاستفادة من هذه الحقوق، تواصل معنا.

                ## 7. التواصل

                لأي استفسار يتعلق بهذه السياسة، يمكنك التواصل معنا عبر التطبيق.
                """
        };

        _cache.Set("legal_privacy", content, TimeSpan.FromHours(24));
        return Ok(content);
    }
}
