# Shopify Store Product Sync

## Overview

A Ruby on Rails application that enables seamless product synchronization between multiple Shopify stores. This app allows merchants to:

- Connect multiple Shopify stores
- View and manage products across different stores
- Selectively sync products between stores
- Maintain consistent product data across their store network

## Tech Stack

### Core Technologies
- **Ruby**: 3.4.1
- **Rails**: 8.0.0
- **Database**: PostgreSQL
- **Development Tunnel**: Ngrok

### Key Features
- Shopify API Integration
- Multi-store Management
- Bulk Product Synchronization
- Real-time Status Updates

## Prerequisites

Before you begin, ensure you have the following installed:

- Ruby 3.4.1
- Rails 8.0.0
- PostgreSQL
- Ngrok
- Git
- Bundler

## Installation

1. **Clone the Repository**
   ```bash
   git clone https://github.com/mmomin7705/shopify_app.git
   cd shopify_app
   ```

2. **Install Dependencies**
   ```bash
   bundle install
   ```

3. **Set Up Shopify Partner Account**
   - Create a new app in your Shopify Partner dashboard
   - Configure app settings and permissions
   - Note down the Client ID and Client Secret

4. **Environment Configuration**
   Create a `.env` file in the root directory with the following variables:
   ```env
   SHOPIFY_API_KEY=your_client_id
   SHOPIFY_API_SECRET=your_client_secret
   APP_URL=your_ngrok_url
   SCOPES=read_products,write_products
   ```

5. **Database Setup**
   ```bash
   rails db:create
   rails db:migrate
   ```

## Running the Application

1. **Start the Rails Server**
   ```bash
   rails s
   ```

2. **Start Ngrok** (in a separate terminal)
   ```bash
   ngrok http 3000
   ```

3. **Update App URL**
   - Copy the Ngrok HTTPS URL
   - Update the APP_URL in your `.env` file
   - Update the App URL and Redirect URL (https://your-ngrok-url/auth/callback) in your Shopify Partner dashboard
   - Go to Development.rb and add url in config.host << "Ngrok_Url"

4. **Access the Application**
   ```
   https://your-ngrok-url/auth/install?shop=your-store-name.myshopify.com
   ```

**Note**: Replace placeholder values (your_client_id, your_client_secret, etc.) with your actual credentials and configuration details.
