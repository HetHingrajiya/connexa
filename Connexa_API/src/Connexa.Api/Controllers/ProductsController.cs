using System.Security.Claims;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Connexa.Api.DTOs;
using Connexa.Api.Services.Products;

namespace Connexa.Api.Controllers;

[ApiController]
[Authorize]
public class ProductsController : ControllerBase
{
    private readonly IProductService _productService;
    private readonly ILogger<ProductsController> _logger;

    public ProductsController(IProductService productService, ILogger<ProductsController> logger)
    {
        _productService = productService;
        _logger = logger;
    }

    private int? GetCurrentMemberId()
    {
        var memberIdClaim = User.FindFirst(ClaimTypes.NameIdentifier)?.Value
            ?? User.FindFirst("sub")?.Value;

        if (int.TryParse(memberIdClaim, out var memberId))
        {
            return memberId;
        }

        return null;
    }

    /// <summary>
    /// Retrieves products owned by the authenticated member.
    /// GET /api/v1/products/my
    /// </summary>
    [HttpGet("api/v1/products/my")]
    [ProducesResponseType(typeof(ApiResponse<List<ProductDto>>), StatusCodes.Status200OK)]
    [ProducesResponseType(typeof(ApiResponse<List<ProductDto>>), StatusCodes.Status401Unauthorized)]
    public async Task<IActionResult> GetMyProducts(CancellationToken cancellationToken)
    {
        var currentMemberId = GetCurrentMemberId();
        if (!currentMemberId.HasValue)
        {
            return Unauthorized(ApiResponse<List<ProductDto>>.Fail("Invalid authentication claims."));
        }

        var products = await _productService.GetMemberProductsAsync(currentMemberId.Value, cancellationToken);
        return Ok(ApiResponse<List<ProductDto>>.Ok(products, products.Count));
    }

    /// <summary>
    /// Retrieves active products across the network, with industry, category, keyword, sorting, and pagination filters.
    /// GET /api/v1/products
    /// </summary>
    [HttpGet("api/v1/products")]
    [ProducesResponseType(typeof(ApiResponse<ProductCatalogResponseDto>), StatusCodes.Status200OK)]
    [ProducesResponseType(typeof(ApiResponse<ProductCatalogResponseDto>), StatusCodes.Status401Unauthorized)]
    public async Task<IActionResult> GetAllProducts(
        [FromQuery] ProductFilterDto filter,
        CancellationToken cancellationToken = default)
    {
        var currentMemberId = GetCurrentMemberId();
        var catalog = await _productService.GetCatalogProductsAsync(filter, currentMemberId, cancellationToken);
        return Ok(ApiResponse<ProductCatalogResponseDto>.Ok(catalog, catalog.TotalCount));
    }


    /// <summary>
    /// Retrieves smart product recommendations tailored to the authenticated member or specified industry.
    /// GET /api/v1/products/recommended
    /// </summary>
    [HttpGet("api/v1/products/recommended")]
    [ProducesResponseType(typeof(ApiResponse<List<ProductDto>>), StatusCodes.Status200OK)]
    [ProducesResponseType(typeof(ApiResponse<List<ProductDto>>), StatusCodes.Status401Unauthorized)]
    public async Task<IActionResult> GetRecommendedProducts(
        [FromQuery] ProductRecommendationFilterDto filter,
        CancellationToken cancellationToken = default)
    {
        var currentMemberId = GetCurrentMemberId();
        var recommended = await _productService.GetRecommendedProductsAsync(currentMemberId, filter, cancellationToken);
        return Ok(ApiResponse<List<ProductDto>>.Ok(recommended, recommended.Count));
    }

    /// <summary>
    /// Retrieves a single product by ID.
    /// GET /api/v1/products/{id}
    /// </summary>
    [HttpGet("api/v1/products/{id:int}")]
    [ProducesResponseType(typeof(ApiResponse<ProductDto>), StatusCodes.Status200OK)]
    [ProducesResponseType(typeof(ApiResponse<ProductDto>), StatusCodes.Status401Unauthorized)]
    [ProducesResponseType(typeof(ApiResponse<ProductDto>), StatusCodes.Status404NotFound)]
    public async Task<IActionResult> GetProductById(int id, CancellationToken cancellationToken)
    {
        var currentMemberId = GetCurrentMemberId();
        var product = await _productService.GetProductByIdAsync(id, currentMemberId, cancellationToken);
        if (product == null)
        {
            return NotFound(ApiResponse<ProductDto>.Fail("Product not found."));
        }

        return Ok(ApiResponse<ProductDto>.Ok(product, 1));
    }

    /// <summary>
    /// Retrieves deterministic related products for a product based on industry, category, tags, and keywords.
    /// GET /api/v1/products/{id}/related
    /// </summary>
    [HttpGet("api/v1/products/{id:int}/related")]
    [ProducesResponseType(typeof(ApiResponse<List<ProductDto>>), StatusCodes.Status200OK)]
    [ProducesResponseType(typeof(ApiResponse<List<ProductDto>>), StatusCodes.Status401Unauthorized)]
    public async Task<IActionResult> GetRelatedProducts(
        int id,
        [FromQuery] int limit = 6,
        CancellationToken cancellationToken = default)
    {
        var currentMemberId = GetCurrentMemberId();
        var related = await _productService.GetRelatedProductsAsync(id, limit, currentMemberId, cancellationToken);
        return Ok(ApiResponse<List<ProductDto>>.Ok(related, related.Count));
    }

    /// <summary>
    /// Creates a new product for the authenticated member.
    /// POST /api/v1/products
    /// </summary>
    [HttpPost("api/v1/products")]
    [ProducesResponseType(typeof(ApiResponse<ProductDto>), StatusCodes.Status201Created)]
    [ProducesResponseType(typeof(ApiResponse<ProductDto>), StatusCodes.Status400BadRequest)]
    [ProducesResponseType(typeof(ApiResponse<ProductDto>), StatusCodes.Status401Unauthorized)]
    public async Task<IActionResult> CreateProduct([FromBody] CreateProductRequestDto dto, CancellationToken cancellationToken)
    {
        var currentMemberId = GetCurrentMemberId();
        if (!currentMemberId.HasValue)
        {
            return Unauthorized(ApiResponse<ProductDto>.Fail("Invalid authentication claims."));
        }

        var (success, message, product) = await _productService.CreateProductAsync(currentMemberId.Value, dto, cancellationToken);
        if (!success)
        {
            return BadRequest(ApiResponse<ProductDto>.Fail(message));
        }

        return StatusCode(StatusCodes.Status201Created, ApiResponse<ProductDto>.Ok(product!, 1));
    }

    /// <summary>
    /// Updates an existing product owned by the authenticated member.
    /// PUT /api/v1/products/{id}
    /// </summary>
    [HttpPut("api/v1/products/{id:int}")]
    [ProducesResponseType(typeof(ApiResponse<ProductDto>), StatusCodes.Status200OK)]
    [ProducesResponseType(typeof(ApiResponse<ProductDto>), StatusCodes.Status400BadRequest)]
    [ProducesResponseType(typeof(ApiResponse<ProductDto>), StatusCodes.Status401Unauthorized)]
    [ProducesResponseType(typeof(ApiResponse<ProductDto>), StatusCodes.Status404NotFound)]
    public async Task<IActionResult> UpdateProduct(int id, [FromBody] UpdateProductRequestDto dto, CancellationToken cancellationToken)
    {
        var currentMemberId = GetCurrentMemberId();
        if (!currentMemberId.HasValue)
        {
            return Unauthorized(ApiResponse<ProductDto>.Fail("Invalid authentication claims."));
        }

        var (success, message, product) = await _productService.UpdateProductAsync(currentMemberId.Value, id, dto, cancellationToken);
        if (!success)
        {
            if (message.Contains("not found", StringComparison.OrdinalIgnoreCase))
            {
                return NotFound(ApiResponse<ProductDto>.Fail(message));
            }

            return BadRequest(ApiResponse<ProductDto>.Fail(message));
        }

        return Ok(ApiResponse<ProductDto>.Ok(product!, 1));
    }

    /// <summary>
    /// Deletes a product owned by the authenticated member.
    /// DELETE /api/v1/products/{id}
    /// </summary>
    [HttpDelete("api/v1/products/{id:int}")]
    [ProducesResponseType(typeof(ApiResponse<bool>), StatusCodes.Status200OK)]
    [ProducesResponseType(typeof(ApiResponse<bool>), StatusCodes.Status400BadRequest)]
    [ProducesResponseType(typeof(ApiResponse<bool>), StatusCodes.Status401Unauthorized)]
    [ProducesResponseType(typeof(ApiResponse<bool>), StatusCodes.Status404NotFound)]
    public async Task<IActionResult> DeleteProduct(int id, CancellationToken cancellationToken)
    {
        var currentMemberId = GetCurrentMemberId();
        if (!currentMemberId.HasValue)
        {
            return Unauthorized(ApiResponse<bool>.Fail("Invalid authentication claims."));
        }

        var (success, message) = await _productService.DeleteProductAsync(currentMemberId.Value, id, cancellationToken);
        if (!success)
        {
            if (message.Contains("not found", StringComparison.OrdinalIgnoreCase))
            {
                return NotFound(ApiResponse<bool>.Fail(message));
            }

            return BadRequest(ApiResponse<bool>.Fail(message));
        }

        return Ok(ApiResponse<bool>.Ok(true, 1));
    }

    /// <summary>
    /// Sends an inquiry regarding a product.
    /// POST /api/v1/products/{id}/inquiries
    /// </summary>
    [HttpPost("api/v1/products/{id:int}/inquiries")]
    [ProducesResponseType(typeof(ApiResponse<ProductInquiryDto>), StatusCodes.Status200OK)]
    [ProducesResponseType(typeof(ApiResponse<ProductInquiryDto>), StatusCodes.Status400BadRequest)]
    [ProducesResponseType(typeof(ApiResponse<ProductInquiryDto>), StatusCodes.Status401Unauthorized)]
    public async Task<IActionResult> SendInquiry(int id, [FromBody] CreateProductInquiryDto dto, CancellationToken cancellationToken)
    {
        var currentMemberId = GetCurrentMemberId();
        if (!currentMemberId.HasValue)
        {
            return Unauthorized(ApiResponse<ProductInquiryDto>.Fail("Invalid authentication claims."));
        }

        var (success, message, inquiry) = await _productService.SendInquiryAsync(currentMemberId.Value, id, dto, cancellationToken);
        if (!success)
        {
            return BadRequest(ApiResponse<ProductInquiryDto>.Fail(message));
        }

        return Ok(ApiResponse<ProductInquiryDto>.Ok(inquiry!, 1));
    }

    /// <summary>
    /// Retrieves received product inquiries for the authenticated member's products.
    /// GET /api/v1/products/inquiries/received
    /// </summary>
    [HttpGet("api/v1/products/inquiries/received")]
    [ProducesResponseType(typeof(ApiResponse<List<ProductInquiryDto>>), StatusCodes.Status200OK)]
    [ProducesResponseType(typeof(ApiResponse<List<ProductInquiryDto>>), StatusCodes.Status401Unauthorized)]
    public async Task<IActionResult> GetReceivedInquiries(CancellationToken cancellationToken)
    {
        var currentMemberId = GetCurrentMemberId();
        if (!currentMemberId.HasValue)
        {
            return Unauthorized(ApiResponse<List<ProductInquiryDto>>.Fail("Invalid authentication claims."));
        }

        var inquiries = await _productService.GetReceivedInquiriesAsync(currentMemberId.Value, cancellationToken);
        return Ok(ApiResponse<List<ProductInquiryDto>>.Ok(inquiries, inquiries.Count));
    }

    /// <summary>
    /// Retrieves sent product inquiries made by the authenticated member.
    /// GET /api/v1/products/inquiries/sent
    /// </summary>
    [HttpGet("api/v1/products/inquiries/sent")]
    [ProducesResponseType(typeof(ApiResponse<List<ProductInquiryDto>>), StatusCodes.Status200OK)]
    [ProducesResponseType(typeof(ApiResponse<List<ProductInquiryDto>>), StatusCodes.Status401Unauthorized)]
    public async Task<IActionResult> GetSentInquiries(CancellationToken cancellationToken)
    {
        var currentMemberId = GetCurrentMemberId();
        if (!currentMemberId.HasValue)
        {
            return Unauthorized(ApiResponse<List<ProductInquiryDto>>.Fail("Invalid authentication claims."));
        }

        var inquiries = await _productService.GetSentInquiriesAsync(currentMemberId.Value, cancellationToken);
        return Ok(ApiResponse<List<ProductInquiryDto>>.Ok(inquiries, inquiries.Count));
    }

    /// <summary>
    /// Retrieves a specific inquiry with ownership/privacy authorization checks.
    /// GET /api/v1/products/inquiries/{id}
    /// </summary>
    [HttpGet("api/v1/products/inquiries/{id:int}")]
    [ProducesResponseType(typeof(ApiResponse<ProductInquiryDto>), StatusCodes.Status200OK)]
    [ProducesResponseType(typeof(ApiResponse<ProductInquiryDto>), StatusCodes.Status401Unauthorized)]
    [ProducesResponseType(typeof(ApiResponse<ProductInquiryDto>), StatusCodes.Status404NotFound)]
    public async Task<IActionResult> GetInquiryById(int id, CancellationToken cancellationToken)
    {
        var currentMemberId = GetCurrentMemberId();
        if (!currentMemberId.HasValue)
        {
            return Unauthorized(ApiResponse<ProductInquiryDto>.Fail("Invalid authentication claims."));
        }

        var inquiry = await _productService.GetInquiryByIdAsync(id, currentMemberId.Value, cancellationToken);
        if (inquiry == null)
        {
            return NotFound(ApiResponse<ProductInquiryDto>.Fail("Inquiry not found or access denied."));
        }

        return Ok(ApiResponse<ProductInquiryDto>.Ok(inquiry, 1));
    }

    /// <summary>
    /// Responds to a received product inquiry.
    /// POST /api/v1/products/inquiries/{id}/respond
    /// </summary>
    [HttpPost("api/v1/products/inquiries/{id:int}/respond")]
    [ProducesResponseType(typeof(ApiResponse<ProductInquiryDto>), StatusCodes.Status200OK)]
    [ProducesResponseType(typeof(ApiResponse<ProductInquiryDto>), StatusCodes.Status400BadRequest)]
    [ProducesResponseType(typeof(ApiResponse<ProductInquiryDto>), StatusCodes.Status401Unauthorized)]
    [ProducesResponseType(typeof(ApiResponse<ProductInquiryDto>), StatusCodes.Status403Forbidden)]
    [ProducesResponseType(typeof(ApiResponse<ProductInquiryDto>), StatusCodes.Status404NotFound)]
    public async Task<IActionResult> RespondToInquiry(int id, [FromBody] RespondToInquiryDto dto, CancellationToken cancellationToken)
    {
        var currentMemberId = GetCurrentMemberId();
        if (!currentMemberId.HasValue)
        {
            return Unauthorized(ApiResponse<ProductInquiryDto>.Fail("Invalid authentication claims."));
        }

        var (success, message, inquiry) = await _productService.RespondToInquiryAsync(currentMemberId.Value, id, dto, cancellationToken);
        if (!success)
        {
            if (message.Contains("not found", StringComparison.OrdinalIgnoreCase))
            {
                return NotFound(ApiResponse<ProductInquiryDto>.Fail(message));
            }
            if (message.Contains("not authorized", StringComparison.OrdinalIgnoreCase))
            {
                return StatusCode(StatusCodes.Status403Forbidden, ApiResponse<ProductInquiryDto>.Fail(message));
            }
            return BadRequest(ApiResponse<ProductInquiryDto>.Fail(message));
        }

        return Ok(ApiResponse<ProductInquiryDto>.Ok(inquiry!, 1));
    }

    /// <summary>
    /// Retrieves product inquiries (defaulting to received or sent via type query param).
    /// GET /api/v1/products/inquiries
    /// </summary>
    [HttpGet("api/v1/products/inquiries")]
    [ProducesResponseType(typeof(ApiResponse<List<ProductInquiryDto>>), StatusCodes.Status200OK)]
    [ProducesResponseType(typeof(ApiResponse<List<ProductInquiryDto>>), StatusCodes.Status401Unauthorized)]
    public async Task<IActionResult> GetInquiries([FromQuery] string? type, CancellationToken cancellationToken)
    {
        var currentMemberId = GetCurrentMemberId();
        if (!currentMemberId.HasValue)
        {
            return Unauthorized(ApiResponse<List<ProductInquiryDto>>.Fail("Invalid authentication claims."));
        }

        if (string.Equals(type, "sent", StringComparison.OrdinalIgnoreCase))
        {
            var sent = await _productService.GetSentInquiriesAsync(currentMemberId.Value, cancellationToken);
            return Ok(ApiResponse<List<ProductInquiryDto>>.Ok(sent, sent.Count));
        }

        var received = await _productService.GetReceivedInquiriesAsync(currentMemberId.Value, cancellationToken);
        return Ok(ApiResponse<List<ProductInquiryDto>>.Ok(received, received.Count));
    }

    /// <summary>
    /// Retrieves live business statistics for the authenticated member dashboard.
    /// GET /api/v1/dashboard/stats
    /// </summary>
    [HttpGet("api/v1/dashboard/stats")]
    [ProducesResponseType(typeof(ApiResponse<DashboardStatsDto>), StatusCodes.Status200OK)]
    [ProducesResponseType(typeof(ApiResponse<DashboardStatsDto>), StatusCodes.Status401Unauthorized)]
    public async Task<IActionResult> GetDashboardStats(CancellationToken cancellationToken)
    {
        var currentMemberId = GetCurrentMemberId();
        if (!currentMemberId.HasValue)
        {
            return Unauthorized(ApiResponse<DashboardStatsDto>.Fail("Invalid authentication claims."));
        }

        var stats = await _productService.GetDashboardStatsAsync(currentMemberId.Value, cancellationToken);
        return Ok(ApiResponse<DashboardStatsDto>.Ok(stats, 1));
    }

    /// <summary>
    /// Retrieves recommended companies for the authenticated member based on industry, group, and offerings.
    /// GET /api/v1/dashboard/recommended-companies
    /// </summary>
    [HttpGet("api/v1/dashboard/recommended-companies")]
    [ProducesResponseType(typeof(ApiResponse<List<RecommendedCompanyDto>>), StatusCodes.Status200OK)]
    [ProducesResponseType(typeof(ApiResponse<List<RecommendedCompanyDto>>), StatusCodes.Status401Unauthorized)]
    public async Task<IActionResult> GetRecommendedCompanies([FromQuery] int limit = 5, CancellationToken cancellationToken = default)
    {
        var currentMemberId = GetCurrentMemberId();
        if (!currentMemberId.HasValue)
        {
            return Unauthorized(ApiResponse<List<RecommendedCompanyDto>>.Fail("Invalid authentication claims."));
        }

        var companies = await _productService.GetRecommendedCompaniesAsync(currentMemberId.Value, limit, cancellationToken);
        return Ok(ApiResponse<List<RecommendedCompanyDto>>.Ok(companies, companies.Count));
    }

    /// <summary>
    /// Records a profile view when a member or guest views a business profile.
    /// POST /api/v1/members/{id}/view
    /// </summary>
    [HttpPost("api/v1/members/{id:int}/view")]
    [ProducesResponseType(typeof(ApiResponse<bool>), StatusCodes.Status200OK)]
    public async Task<IActionResult> RecordProfileView(int id, CancellationToken cancellationToken)
    {
        var currentMemberId = GetCurrentMemberId();
        await _productService.RecordCompanyViewAsync(id, currentMemberId, cancellationToken);
        return Ok(ApiResponse<bool>.Ok(true, 1));
    }
}
