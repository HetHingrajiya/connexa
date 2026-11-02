using System.Net;
using System.Net.Http.Headers;
using System.Net.Http.Json;
using System.Text.Json;
using Microsoft.AspNetCore.Mvc.Testing;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.DependencyInjection;
using Connexa.Api.Data;
using Connexa.Api.DTOs;
using Connexa.Api.Entities;
using Connexa.Api.Services.Auth;
using Xunit;

namespace Connexa.Api.Tests.Integration;

public class EndToEndIntegrationAuditTests : IClassFixture<WebApplicationFactory<Program>>
{
    private readonly WebApplicationFactory<Program> _factory;
    private readonly HttpClient _client;
    private static readonly JsonSerializerOptions JsonOptions = new()
    {
        PropertyNameCaseInsensitive = true
    };

    public EndToEndIntegrationAuditTests(WebApplicationFactory<Program> factory)
    {
        _factory = factory;
        _client = factory.CreateClient();
    }

    private async Task<(Member Member, string Token, BusinessProfile Profile)> CreateTestMemberAsync(string name, string role = "Member")
    {
        using var scope = _factory.Services.CreateScope();
        var db = scope.ServiceProvider.GetRequiredService<ConnexaDbContext>();
        var tokenService = scope.ServiceProvider.GetRequiredService<ITokenService>();

        var email = $"audit_{Guid.NewGuid():N}@connexa.com";
        var phone = "+91" + Random.Shared.NextInt64(7000000000, 7999999999);

        var member = new Member
        {
            FullName = name,
            CountryCode = "+91",
            PhoneNumber = phone,
            Email = email,
            PrimaryProfileType = ProfileTypeEnum.BusinessCompany,
            VerifiedMethod = "Email",
            VerifiedDestination = email,
            Role = role,
            IsActive = true,
            CreatedAtUtc = DateTime.UtcNow
        };

        db.Members.Add(member);
        await db.SaveChangesAsync();

        var businessProfile = new BusinessProfile
        {
            MemberId = member.Id,
            CompanyName = $"{name} Enterprise Ltd",
            IndustryId = 4, // Manufacturing
            BusinessGroupId = 3,
            SubGroupId = 3,
            CategoryId = 13,
            BusinessCapabilities = "Industrial Manufacturing & Assembly",
            BusinessDescription = $"{name} official commercial account on Connexa network.",
            City = "Ahmedabad",
            State = "Gujarat",
            Pincode = "380015",
            VerificationStatus = BusinessVerificationStatus.NotSubmitted
        };
        db.BusinessProfiles.Add(businessProfile);
        await db.SaveChangesAsync();

        var token = tokenService.GenerateAccessToken(member);
        return (member, token, businessProfile);
    }

    [Fact]
    public async Task CompleteEndToEndB2BWorkflow_16Steps_SucceedsWithAuditIntegrity()
    {
        // -------------------------------------------------------------
        // Step 1: Buyer registers and authenticates
        // -------------------------------------------------------------
        var (buyer, buyerToken, buyerProfile) = await CreateTestMemberAsync("Audit Buyer Corp");
        Assert.NotNull(buyerToken);
        Assert.True(buyer.Id > 0);

        // -------------------------------------------------------------
        // Step 2: Supplier registers and authenticates
        // -------------------------------------------------------------
        var (supplier, supplierToken, supplierProfile) = await CreateTestMemberAsync("Audit Supplier Machinery");
        Assert.NotNull(supplierToken);
        Assert.True(supplier.Id > 0);

        // -------------------------------------------------------------
        // Step 3: Admin verifies Supplier profile
        // -------------------------------------------------------------
        var (admin, adminToken, _) = await CreateTestMemberAsync("Connexa System Admin", role: "Admin");
        
        using (var scope = _factory.Services.CreateScope())
        {
            var db = scope.ServiceProvider.GetRequiredService<ConnexaDbContext>();
            var vReq = new BusinessVerificationRequest
            {
                MemberId = supplier.Id,
                BusinessProfileId = supplierProfile.Id,
                BusinessRegistrationNumber = "GSTIN24AAACC1234F1Z5",
                RegisteredAddress = "GIDC Industrial Estate, Vatva",
                City = "Ahmedabad",
                State = "Gujarat",
                Pincode = "382445",
                Status = BusinessVerificationStatus.PendingReview,
                SubmittedAtUtc = DateTime.UtcNow
            };
            db.BusinessVerificationRequests.Add(vReq);
            await db.SaveChangesAsync();

            // Admin approves verification
            using var approveReq = new HttpRequestMessage(HttpMethod.Post, $"/api/v1/admin/verifications/{vReq.Id}/approve");
            approveReq.Headers.Authorization = new AuthenticationHeaderValue("Bearer", adminToken);
            var approveResp = await _client.SendAsync(approveReq);
            Assert.Equal(HttpStatusCode.OK, approveResp.StatusCode);

            // Supplier checks status -> Approved / Verified
            using var statusReq = new HttpRequestMessage(HttpMethod.Get, "/api/v1/business-verification/status");
            statusReq.Headers.Authorization = new AuthenticationHeaderValue("Bearer", supplierToken);
            var statusResp = await _client.SendAsync(statusReq);
            Assert.Equal(HttpStatusCode.OK, statusResp.StatusCode);
            var statusData = await statusResp.Content.ReadFromJsonAsync<ApiResponse<VerificationStatusResponseDto>>(JsonOptions);
            Assert.NotNull(statusData?.Data);
            Assert.Equal("Approved", statusData.Data.Status);
        }

        // -------------------------------------------------------------
        // Step 4: Supplier adds a product
        // -------------------------------------------------------------
        var createProductDto = new CreateProductRequestDto(
            Name: "Heavy Duty CNC Milling Machine V5",
            Description: "High-precision 5-axis CNC vertical milling machine with digital Siemens controller.",
            Category: "Industrial Machinery",
            SubCategory: "CNC Milling",
            Tags: new List<string> { "CNC", "Milling", "HeavyDuty", "B2B" },
            ImageUrl: "https://connexa.io/uploads/cnc-v5.jpg",
            Specifications: new Dictionary<string, string>
            {
                { "Spindle Speed", "12000 RPM" },
                { "Table Size", "1200 x 600 mm" },
                { "Power", "15 kW" }
            },
            IndustryId: 4
        );

        using var addProdReq = new HttpRequestMessage(HttpMethod.Post, "/api/v1/products");
        addProdReq.Headers.Authorization = new AuthenticationHeaderValue("Bearer", supplierToken);
        addProdReq.Content = JsonContent.Create(createProductDto);
        var addProdResp = await _client.SendAsync(addProdReq);
        Assert.Equal(HttpStatusCode.Created, addProdResp.StatusCode);
        var prodResult = await addProdResp.Content.ReadFromJsonAsync<ApiResponse<ProductDto>>(JsonOptions);
        Assert.NotNull(prodResult?.Data);
        var productId = prodResult.Data.Id;
        Assert.True(productId > 0);

        // -------------------------------------------------------------
        // Step 5: Buyer discovers supplier and product
        // -------------------------------------------------------------
        using var discProdReq = new HttpRequestMessage(HttpMethod.Get, $"/api/v1/products/{productId}");
        discProdReq.Headers.Authorization = new AuthenticationHeaderValue("Bearer", buyerToken);
        var discProdResp = await _client.SendAsync(discProdReq);
        Assert.Equal(HttpStatusCode.OK, discProdResp.StatusCode);
        var fetchedProd = await discProdResp.Content.ReadFromJsonAsync<ApiResponse<ProductDto>>(JsonOptions);
        Assert.NotNull(fetchedProd?.Data);
        Assert.Equal(productId, fetchedProd.Data.Id);

        // -------------------------------------------------------------
        // Step 6: Buyer sends a connection request to Supplier
        // -------------------------------------------------------------
        var connDto = new CreateConnectionRequestDto(
            RecipientMemberId: supplier.Id,
            Note: "Hello, we are interested in procurement partnerships for CNC equipment."
        );
        using var connReq = new HttpRequestMessage(HttpMethod.Post, "/api/v1/connections/requests");
        connReq.Headers.Authorization = new AuthenticationHeaderValue("Bearer", buyerToken);
        connReq.Content = JsonContent.Create(connDto);
        var connResp = await _client.SendAsync(connReq);
        Assert.Equal(HttpStatusCode.OK, connResp.StatusCode);
        var connResult = await connResp.Content.ReadFromJsonAsync<ApiResponse<ConnectionDto>>(JsonOptions);
        Assert.NotNull(connResult?.Data);
        var connectionId = connResult.Data.Id;
        Assert.True(connectionId > 0);

        // -------------------------------------------------------------
        // Step 7: Supplier receives and accepts connection request
        // -------------------------------------------------------------
        using var acceptReq = new HttpRequestMessage(HttpMethod.Post, $"/api/v1/connections/requests/{connectionId}/accept");
        acceptReq.Headers.Authorization = new AuthenticationHeaderValue("Bearer", supplierToken);
        var acceptResp = await _client.SendAsync(acceptReq);
        Assert.Equal(HttpStatusCode.OK, acceptResp.StatusCode);

        // -------------------------------------------------------------
        // Step 8: Buyer creates an RFQ for the Product
        // -------------------------------------------------------------
        var createRfqDto = new CreateRfqDto(
            ProductId: productId,
            Quantity: 2,
            UnitOfMeasurement: "Units",
            TargetPrice: 4500000.00m,
            RequiredDeliveryDateUtc: DateTime.UtcNow.AddDays(30),
            DeliveryLocation: "Sanand Industrial Park, Ahmedabad",
            AdditionalSpecifications: "Requires on-site commissioning and 2-year AMC warranty.",
            Title: "Procurement of 2 Units CNC Milling Machine V5"
        );
        using var rfqReq = new HttpRequestMessage(HttpMethod.Post, "/api/v1/rfqs");
        rfqReq.Headers.Authorization = new AuthenticationHeaderValue("Bearer", buyerToken);
        rfqReq.Content = JsonContent.Create(createRfqDto);
        var rfqResp = await _client.SendAsync(rfqReq);
        Assert.Equal(HttpStatusCode.Created, rfqResp.StatusCode);
        var rfqResult = await rfqResp.Content.ReadFromJsonAsync<ApiResponse<RfqDto>>(JsonOptions);
        Assert.NotNull(rfqResult?.Data);
        var rfqId = rfqResult.Data.Id;
        Assert.True(rfqId > 0);

        // -------------------------------------------------------------
        // Step 9: Supplier receives RFQ and submits a Quotation
        // -------------------------------------------------------------
        using var getReceivedRfqReq = new HttpRequestMessage(HttpMethod.Get, "/api/v1/rfqs/received");
        getReceivedRfqReq.Headers.Authorization = new AuthenticationHeaderValue("Bearer", supplierToken);
        var getReceivedRfqResp = await _client.SendAsync(getReceivedRfqReq);
        Assert.Equal(HttpStatusCode.OK, getReceivedRfqResp.StatusCode);

        var submitQuoteDto = new SubmitQuotationDto(
            UnitPrice: 2350000.00m,
            Quantity: 2,
            TaxRatePercent: 18.00m,
            ShippingCharges: 25000.00m,
            ValidUntilUtc: DateTime.UtcNow.AddDays(14),
            EstimatedDeliveryTime: "15 to 20 Business Days",
            TermsAndConditions: "30% Advance, 70% against delivery and installation."
        );
        using var quoteReq = new HttpRequestMessage(HttpMethod.Post, $"/api/v1/rfqs/{rfqId}/quotations");
        quoteReq.Headers.Authorization = new AuthenticationHeaderValue("Bearer", supplierToken);
        quoteReq.Content = JsonContent.Create(submitQuoteDto);
        var quoteResp = await _client.SendAsync(quoteReq);
        Assert.Equal(HttpStatusCode.Created, quoteResp.StatusCode);
        var quoteResult = await quoteResp.Content.ReadFromJsonAsync<ApiResponse<QuotationDto>>(JsonOptions);
        Assert.NotNull(quoteResult?.Data);
        var quotationId = quoteResult.Data.Id;
        Assert.True(quotationId > 0);

        // -------------------------------------------------------------
        // Step 10: Buyer views quotations and accepts the quotation
        // -------------------------------------------------------------
        using var viewQuotesReq = new HttpRequestMessage(HttpMethod.Get, $"/api/v1/rfqs/{rfqId}/quotations");
        viewQuotesReq.Headers.Authorization = new AuthenticationHeaderValue("Bearer", buyerToken);
        var viewQuotesResp = await _client.SendAsync(viewQuotesReq);
        Assert.Equal(HttpStatusCode.OK, viewQuotesResp.StatusCode);
        var quotesList = await viewQuotesResp.Content.ReadFromJsonAsync<ApiResponse<List<QuotationDto>>>(JsonOptions);
        Assert.NotNull(quotesList?.Data);
        Assert.Contains(quotesList.Data, q => q.Id == quotationId);

        var acceptQuoteDto = new DecideQuotationDto(Decision: "Accept", Notes: "Quotation accepted as per commercial terms.");
        using var decideReq = new HttpRequestMessage(HttpMethod.Post, $"/api/v1/rfqs/quotations/{quotationId}/decide");
        decideReq.Headers.Authorization = new AuthenticationHeaderValue("Bearer", buyerToken);
        decideReq.Content = JsonContent.Create(acceptQuoteDto);
        var decideResp = await _client.SendAsync(decideReq);
        var decideContent = await decideResp.Content.ReadAsStringAsync();
        Assert.True(decideResp.StatusCode == HttpStatusCode.OK, $"Decide failed with {decideResp.StatusCode}: {decideContent}");

        // -------------------------------------------------------------
        // Step 11: Buyer creates Order from accepted quotation
        // -------------------------------------------------------------
        var createOrderDto = new CreateOrderDto(
            QuotationId: quotationId,
            DeliveryAddress: "Plot 42, Sanand Industrial Estate, Ahmedabad, Gujarat 382110",
            ExpectedDeliveryDateUtc: DateTime.UtcNow.AddDays(20),
            Notes: "Please coordinate with site engineer Mr. Sharma for unloading."
        );
        using var orderReq = new HttpRequestMessage(HttpMethod.Post, "/api/v1/orders");
        orderReq.Headers.Authorization = new AuthenticationHeaderValue("Bearer", buyerToken);
        orderReq.Content = JsonContent.Create(createOrderDto);
        var orderResp = await _client.SendAsync(orderReq);
        Assert.Equal(HttpStatusCode.Created, orderResp.StatusCode);
        var orderResult = await orderResp.Content.ReadFromJsonAsync<ApiResponse<OrderDto>>(JsonOptions);
        Assert.NotNull(orderResult?.Data);
        var orderId = orderResult.Data.Id;
        Assert.True(orderId > 0);
        Assert.Equal("PendingConfirmation", orderResult.Data.Status);

        // -------------------------------------------------------------
        // Step 12: Supplier receives order and confirms it
        // -------------------------------------------------------------
        using var recOrdersReq = new HttpRequestMessage(HttpMethod.Get, "/api/v1/orders/received");
        recOrdersReq.Headers.Authorization = new AuthenticationHeaderValue("Bearer", supplierToken);
        var recOrdersResp = await _client.SendAsync(recOrdersReq);
        Assert.Equal(HttpStatusCode.OK, recOrdersResp.StatusCode);
        var recOrders = await recOrdersResp.Content.ReadFromJsonAsync<ApiResponse<List<OrderDto>>>(JsonOptions);
        Assert.NotNull(recOrders?.Data);
        Assert.Contains(recOrders.Data, o => o.Id == orderId);

        var confirmOrderDto = new ConfirmOrderDto(Remarks: "Purchase order accepted and queued for production.");
        using var confirmOrderReq = new HttpRequestMessage(HttpMethod.Post, $"/api/v1/orders/{orderId}/confirm");
        confirmOrderReq.Headers.Authorization = new AuthenticationHeaderValue("Bearer", supplierToken);
        confirmOrderReq.Content = JsonContent.Create(confirmOrderDto);
        var confirmOrderResp = await _client.SendAsync(confirmOrderReq);
        Assert.Equal(HttpStatusCode.OK, confirmOrderResp.StatusCode);

        // -------------------------------------------------------------
        // Step 13: Supplier updates order status to Processing
        // -------------------------------------------------------------
        var processOrderDto = new ProcessOrderDto(Remarks: "Machine assembly in progress at Vatva unit.");
        using var processOrderReq = new HttpRequestMessage(HttpMethod.Post, $"/api/v1/orders/{orderId}/process");
        processOrderReq.Headers.Authorization = new AuthenticationHeaderValue("Bearer", supplierToken);
        processOrderReq.Content = JsonContent.Create(processOrderDto);
        var processOrderResp = await _client.SendAsync(processOrderReq);
        Assert.Equal(HttpStatusCode.OK, processOrderResp.StatusCode);

        // -------------------------------------------------------------
        // Step 14: Client receives the goods and completes the order
        // -------------------------------------------------------------
        var completeOrderDto = new DeliverOrderDto(Remarks: "Consignment received, inspected and verified in perfect condition.");
        using var completeOrderReq = new HttpRequestMessage(HttpMethod.Post, $"/api/v1/orders/{orderId}/complete");
        completeOrderReq.Headers.Authorization = new AuthenticationHeaderValue("Bearer", buyerToken);
        completeOrderReq.Content = JsonContent.Create(completeOrderDto);
        var completeOrderResp = await _client.SendAsync(completeOrderReq);
        Assert.Equal(HttpStatusCode.OK, completeOrderResp.StatusCode);
        var completedOrderResult = await completeOrderResp.Content.ReadFromJsonAsync<ApiResponse<OrderDto>>(JsonOptions);
        Assert.NotNull(completedOrderResult?.Data);
        Assert.Equal("Delivered", completedOrderResult.Data.Status);

        // -------------------------------------------------------------
        // Step 15: Both users see Completed order in history
        // -------------------------------------------------------------
        using var buyerHistoryReq = new HttpRequestMessage(HttpMethod.Get, $"/api/v1/orders/{orderId}");
        buyerHistoryReq.Headers.Authorization = new AuthenticationHeaderValue("Bearer", buyerToken);
        var buyerHistoryResp = await _client.SendAsync(buyerHistoryReq);
        Assert.Equal(HttpStatusCode.OK, buyerHistoryResp.StatusCode);
        var buyerOrder = await buyerHistoryResp.Content.ReadFromJsonAsync<ApiResponse<OrderDto>>(JsonOptions);
        Assert.NotNull(buyerOrder?.Data);
        Assert.Equal("Delivered", buyerOrder.Data.Status);
        Assert.NotEmpty(buyerOrder.Data.StatusHistory);

        using var supplierHistoryReq = new HttpRequestMessage(HttpMethod.Get, $"/api/v1/orders/{orderId}");
        supplierHistoryReq.Headers.Authorization = new AuthenticationHeaderValue("Bearer", supplierToken);
        var supplierHistoryResp = await _client.SendAsync(supplierHistoryReq);
        Assert.Equal(HttpStatusCode.OK, supplierHistoryResp.StatusCode);
        var supplierOrder = await supplierHistoryResp.Content.ReadFromJsonAsync<ApiResponse<OrderDto>>(JsonOptions);
        Assert.NotNull(supplierOrder?.Data);
        Assert.Equal("Delivered", supplierOrder.Data.Status);

        // -------------------------------------------------------------
        // Step 16: Notifications received and read status verified
        // -------------------------------------------------------------
        using var notifReq = new HttpRequestMessage(HttpMethod.Get, "/api/v1/notifications");
        notifReq.Headers.Authorization = new AuthenticationHeaderValue("Bearer", supplierToken);
        var notifResp = await _client.SendAsync(notifReq);
        Assert.Equal(HttpStatusCode.OK, notifResp.StatusCode);
        var notifData = await notifResp.Content.ReadFromJsonAsync<ApiResponse<PaginatedNotificationsDto>>(JsonOptions);
        Assert.NotNull(notifData?.Data);
        Assert.NotEmpty(notifData.Data.Items);

        // Mark notification as read
        var firstNotifId = notifData.Data.Items.First().Id;
        var markReadDto = new MarkNotificationsReadRequestDto(new List<int> { firstNotifId }, MarkAll: false);
        using var markReadReq = new HttpRequestMessage(HttpMethod.Post, "/api/v1/notifications/mark-read");
        markReadReq.Headers.Authorization = new AuthenticationHeaderValue("Bearer", supplierToken);
        markReadReq.Content = JsonContent.Create(markReadDto);
        var markReadResp = await _client.SendAsync(markReadReq);
        Assert.Equal(HttpStatusCode.OK, markReadResp.StatusCode);
    }

    [Fact]
    public async Task SecurityAndNegativeTesting_EnforcesStrictAccessAndStateBoundaries()
    {
        var (buyer, buyerToken, _) = await CreateTestMemberAsync("Sec Buyer");
        var (supplier, supplierToken, _) = await CreateTestMemberAsync("Sec Supplier");
        var (thirdParty, thirdPartyToken, _) = await CreateTestMemberAsync("Sec Intruder");

        // 1. Unauthenticated request -> 401 Unauthorized
        var unauthResp = await _client.GetAsync("/api/v1/orders/my");
        Assert.Equal(HttpStatusCode.Unauthorized, unauthResp.StatusCode);

        // 2. Non-admin attempting to approve admin verification -> 403 Forbidden
        using var forbiddenReq = new HttpRequestMessage(HttpMethod.Post, "/api/v1/admin/verifications/1/approve");
        forbiddenReq.Headers.Authorization = new AuthenticationHeaderValue("Bearer", buyerToken);
        var forbiddenResp = await _client.SendAsync(forbiddenReq);
        Assert.Equal(HttpStatusCode.Forbidden, forbiddenResp.StatusCode);

        // 3. Create a product under supplier
        var createProductDto = new CreateProductRequestDto(
            Name: "Security Test Lathe",
            Description: "CNC test lathe machine",
            Category: "Machinery",
            IndustryId: 4
        );
        using var addProdReq = new HttpRequestMessage(HttpMethod.Post, "/api/v1/products");
        addProdReq.Headers.Authorization = new AuthenticationHeaderValue("Bearer", supplierToken);
        addProdReq.Content = JsonContent.Create(createProductDto);
        var addProdResp = await _client.SendAsync(addProdReq);
        var prodResult = await addProdResp.Content.ReadFromJsonAsync<ApiResponse<ProductDto>>(JsonOptions);
        var productId = prodResult!.Data!.Id;

        // 4. Unauthorized third party attempting to update supplier's product -> 400 or 404
        var updateDto = new UpdateProductRequestDto("Hacked Product", "Hacked", "Machinery");
        using var hackProdReq = new HttpRequestMessage(HttpMethod.Put, $"/api/v1/products/{productId}");
        hackProdReq.Headers.Authorization = new AuthenticationHeaderValue("Bearer", thirdPartyToken);
        hackProdReq.Content = JsonContent.Create(updateDto);
        var hackProdResp = await _client.SendAsync(hackProdReq);
        Assert.True(hackProdResp.StatusCode == HttpStatusCode.NotFound || hackProdResp.StatusCode == HttpStatusCode.BadRequest);

        // 5. Create RFQ and Quotation
        var rfqDto = new CreateRfqDto(productId, 1, "Unit", Title: "RFQ Sec Test");
        using var rfqReq = new HttpRequestMessage(HttpMethod.Post, "/api/v1/rfqs");
        rfqReq.Headers.Authorization = new AuthenticationHeaderValue("Bearer", buyerToken);
        rfqReq.Content = JsonContent.Create(rfqDto);
        var rfqResp = await _client.SendAsync(rfqReq);
        var rfqResult = await rfqResp.Content.ReadFromJsonAsync<ApiResponse<RfqDto>>(JsonOptions);
        var rfqId = rfqResult!.Data!.Id;

        var quoteDto = new SubmitQuotationDto(100000m, 1);
        using var quoteReq = new HttpRequestMessage(HttpMethod.Post, $"/api/v1/rfqs/{rfqId}/quotations");
        quoteReq.Headers.Authorization = new AuthenticationHeaderValue("Bearer", supplierToken);
        quoteReq.Content = JsonContent.Create(quoteDto);
        var quoteResp = await _client.SendAsync(quoteReq);
        var quoteResult = await quoteResp.Content.ReadFromJsonAsync<ApiResponse<QuotationDto>>(JsonOptions);
        var quotationId = quoteResult!.Data!.Id;

        // 6. Third party attempting to accept supplier's quotation -> 403 Forbidden
        var decideDto = new DecideQuotationDto(Decision: "Accept");
        using var hackDecideReq = new HttpRequestMessage(HttpMethod.Post, $"/api/v1/rfqs/quotations/{quotationId}/decide");
        hackDecideReq.Headers.Authorization = new AuthenticationHeaderValue("Bearer", thirdPartyToken);
        hackDecideReq.Content = JsonContent.Create(decideDto);
        var hackDecideResp = await _client.SendAsync(hackDecideReq);
        Assert.Equal(HttpStatusCode.Forbidden, hackDecideResp.StatusCode);

        // 7. Creating an order before quotation is accepted -> 400 BadRequest
        var prematureOrderDto = new CreateOrderDto(quotationId, "123 Street");
        using var premOrderReq = new HttpRequestMessage(HttpMethod.Post, "/api/v1/orders");
        premOrderReq.Headers.Authorization = new AuthenticationHeaderValue("Bearer", buyerToken);
        premOrderReq.Content = JsonContent.Create(prematureOrderDto);
        var premOrderResp = await _client.SendAsync(premOrderReq);
        Assert.Equal(HttpStatusCode.BadRequest, premOrderResp.StatusCode);

        // 8. Accept quotation properly
        using var legitDecideReq = new HttpRequestMessage(HttpMethod.Post, $"/api/v1/rfqs/quotations/{quotationId}/decide");
        legitDecideReq.Headers.Authorization = new AuthenticationHeaderValue("Bearer", buyerToken);
        legitDecideReq.Content = JsonContent.Create(decideDto);
        var legitDecideResp = await _client.SendAsync(legitDecideReq);
        Assert.Equal(HttpStatusCode.OK, legitDecideResp.StatusCode);

        // 9. Unauthorized member attempting to create order on buyer's accepted quotation -> 403 Forbidden
        using var hackOrderReq = new HttpRequestMessage(HttpMethod.Post, "/api/v1/orders");
        hackOrderReq.Headers.Authorization = new AuthenticationHeaderValue("Bearer", thirdPartyToken);
        hackOrderReq.Content = JsonContent.Create(prematureOrderDto);
        var hackOrderResp = await _client.SendAsync(hackOrderReq);
        Assert.True(hackOrderResp.StatusCode == HttpStatusCode.Forbidden || hackOrderResp.StatusCode == HttpStatusCode.BadRequest);

        // 10. Buyer creates order
        using var legitOrderReq = new HttpRequestMessage(HttpMethod.Post, "/api/v1/orders");
        legitOrderReq.Headers.Authorization = new AuthenticationHeaderValue("Bearer", buyerToken);
        legitOrderReq.Content = JsonContent.Create(prematureOrderDto);
        var legitOrderResp = await _client.SendAsync(legitOrderReq);
        Assert.Equal(HttpStatusCode.Created, legitOrderResp.StatusCode);
        var orderResult = await legitOrderResp.Content.ReadFromJsonAsync<ApiResponse<OrderDto>>(JsonOptions);
        var orderId = orderResult!.Data!.Id;

        // 11. Duplicate order creation on the same quotation -> 409 Conflict or 400 BadRequest
        using var dupOrderReq = new HttpRequestMessage(HttpMethod.Post, "/api/v1/orders");
        dupOrderReq.Headers.Authorization = new AuthenticationHeaderValue("Bearer", buyerToken);
        dupOrderReq.Content = JsonContent.Create(prematureOrderDto);
        var dupOrderResp = await _client.SendAsync(dupOrderReq);
        Assert.True(dupOrderResp.StatusCode == HttpStatusCode.Conflict || dupOrderResp.StatusCode == HttpStatusCode.BadRequest);

        // 12. Unauthorized third party attempting to complete/deliver order -> 400 or 403
        var deliverDto = new DeliverOrderDto("Unauthorized handover");
        using var hackDeliverReq = new HttpRequestMessage(HttpMethod.Post, $"/api/v1/orders/{orderId}/complete");
        hackDeliverReq.Headers.Authorization = new AuthenticationHeaderValue("Bearer", thirdPartyToken);
        hackDeliverReq.Content = JsonContent.Create(deliverDto);
        var hackDeliverResp = await _client.SendAsync(hackDeliverReq);
        Assert.True(hackDeliverResp.StatusCode == HttpStatusCode.BadRequest || hackDeliverResp.StatusCode == HttpStatusCode.Forbidden);

        // 13. Invalid state transition: attempting to ship order while still in PendingConfirmation -> 400 BadRequest
        var shipDto = new ShipOrderDto("Bluedart", "TRK12345");
        using var invalidShipReq = new HttpRequestMessage(HttpMethod.Post, $"/api/v1/orders/{orderId}/ship");
        invalidShipReq.Headers.Authorization = new AuthenticationHeaderValue("Bearer", supplierToken);
        invalidShipReq.Content = JsonContent.Create(shipDto);
        var invalidShipResp = await _client.SendAsync(invalidShipReq);
        Assert.Equal(HttpStatusCode.BadRequest, invalidShipResp.StatusCode);
    }
}
