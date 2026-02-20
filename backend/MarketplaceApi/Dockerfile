# Use Microsoft's official .NET image.
# https://hub.docker.com/_/microsoft-dotnet-aspnet/
FROM mcr.microsoft.com/dotnet/aspnet:8.0 AS base
WORKDIR /app
EXPOSE 8080
EXPOSE 8081

# Use Microsoft's official .NET SDK image to build the app
# https://hub.docker.com/_/microsoft-dotnet-sdk/
FROM mcr.microsoft.com/dotnet/sdk:8.0 AS build
WORKDIR /src
COPY ["MarketplaceApi.csproj", "./"]
RUN dotnet restore "MarketplaceApi.csproj"
COPY . .
WORKDIR "/src/."
RUN dotnet build "MarketplaceApi.csproj" -c Release -o /app/build

FROM build AS publish
RUN dotnet publish "MarketplaceApi.csproj" -c Release -o /app/publish /p:UseAppHost=false

FROM base AS final
WORKDIR /app
COPY --from=publish /app/publish .
ENTRYPOINT ["dotnet", "MarketplaceApi.dll"]
