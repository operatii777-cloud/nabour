/**
 * FriendsRide Delivery Widget
 * 
 * Widget JavaScript embeddable pentru integrarea FriendsRide Delivery
 * în site-uri web ale restaurante
 * 
 * Usage:
 * <script src="https://cdn.friendsride.com/widget/friendsride-widget.js"></script>
 * <div id="friendsride-widget" data-restaurant-id="rest_123"></div>
 */

(function() {
  'use strict';

  // Configuration
  const WIDGET_VERSION = '1.0.0';
  const API_BASE_URL = 'https://us-central1-friendsride.cloudfunctions.net';
  const WIDGET_CDN_URL = 'https://cdn.friendsride.com';

  /**
   * FriendsRide Widget Class
   */
  class FriendsRideWidget {
    constructor(config) {
      this.config = {
        restaurantId: config.restaurantId || null,
        containerId: config.containerId || 'friendsride-widget',
        theme: config.theme || 'light',
        language: config.language || 'ro',
        apiKey: config.apiKey || null,
        ...config,
      };

      this.container = null;
      this.cart = [];
      this.restaurant = null;
      this.menu = [];
      this.isInitialized = false;

      this.init();
    }

    /**
     * Initialize widget
     */
    async init() {
      if (this.isInitialized) {
        return;
      }

      // Find container
      this.container = document.getElementById(this.config.containerId);
      if (!this.container) {
        console.error(`FriendsRide Widget: Container #${this.config.containerId} not found`);
        return;
      }

      // Load restaurant data
      if (this.config.restaurantId) {
        await this.loadRestaurant();
        await this.loadMenu();
      }

      // Render widget
      this.render();

      this.isInitialized = true;
    }

    /**
     * Load restaurant data
     */
    async loadRestaurant() {
      try {
        const response = await fetch(
          `${API_BASE_URL}/api/delivery/restaurants/${this.config.restaurantId}`,
          {
            headers: {
              'Authorization': this.config.apiKey ? `Bearer ${this.config.apiKey}` : '',
            },
          }
        );

        if (response.ok) {
          this.restaurant = await response.json();
        }
      } catch (error) {
        console.error('Error loading restaurant:', error);
      }
    }

    /**
     * Load menu
     */
    async loadMenu() {
      try {
        const response = await fetch(
          `${API_BASE_URL}/api/delivery/restaurants/${this.config.restaurantId}/menu`,
          {
            headers: {
              'Authorization': this.config.apiKey ? `Bearer ${this.config.apiKey}` : '',
            },
          }
        );

        if (response.ok) {
          const data = await response.json();
          this.menu = data.products || [];
        }
      } catch (error) {
        console.error('Error loading menu:', error);
      }
    }

    /**
     * Render widget
     */
    render() {
      if (!this.container) {
        return;
      }

      this.container.innerHTML = `
        <div class="friendsride-widget" data-theme="${this.config.theme}">
          <div class="friendsride-widget-header">
            <h3>${this.restaurant?.name || 'FriendsRide Delivery'}</h3>
            <button class="friendsride-widget-close" onclick="this.closest('.friendsride-widget').style.display='none'">×</button>
          </div>
          <div class="friendsride-widget-content">
            ${this.renderMenu()}
          </div>
          <div class="friendsride-widget-footer">
            <div class="friendsride-widget-cart">
              <span class="friendsride-widget-cart-count">${this.cart.length}</span>
              <button class="friendsride-widget-cart-button" onclick="window.friendsrideWidget.showCart()">
                Vezi coș (${this.getCartTotal().toFixed(2)} RON)
              </button>
            </div>
          </div>
        </div>
      `;

      // Inject styles
      this.injectStyles();
    }

    /**
     * Render menu
     */
    renderMenu() {
      if (this.menu.length === 0) {
        return '<p>Meniul se încarcă...</p>';
      }

      const menuByCategory = this.groupMenuByCategory();

      return Object.keys(menuByCategory).map(category => `
        <div class="friendsride-widget-category">
          <h4>${category}</h4>
          <div class="friendsride-widget-products">
            ${menuByCategory[category].map(product => this.renderProduct(product)).join('')}
          </div>
        </div>
      `).join('');
    }

    /**
     * Render product
     */
    renderProduct(product) {
      return `
        <div class="friendsride-widget-product">
          ${product.imageUrl ? `<img src="${product.imageUrl}" alt="${product.name}" />` : ''}
          <div class="friendsride-widget-product-info">
            <h5>${product.name}</h5>
            <p>${product.description || ''}</p>
            <div class="friendsride-widget-product-footer">
              <span class="friendsride-widget-product-price">${product.price.toFixed(2)} RON</span>
              <button class="friendsride-widget-add-button" onclick="window.friendsrideWidget.addToCart('${product.id}')">
                Adaugă
              </button>
            </div>
          </div>
        </div>
      `;
    }

    /**
     * Group menu by category
     */
    groupMenuByCategory() {
      const grouped = {};
      for (const product of this.menu) {
        const category = product.category || 'Other';
        if (!grouped[category]) {
          grouped[category] = [];
        }
        grouped[category].push(product);
      }
      return grouped;
    }

    /**
     * Add product to cart
     */
    addToCart(productId) {
      const product = this.menu.find(p => p.id === productId);
      if (!product) {
        return;
      }

      this.cart.push({
        id: product.id,
        name: product.name,
        price: product.price,
        quantity: 1,
      });

      this.updateCartUI();
    }

    /**
     * Get cart total
     */
    getCartTotal() {
      return this.cart.reduce((sum, item) => sum + (item.price * item.quantity), 0);
    }

    /**
     * Update cart UI
     */
    updateCartUI() {
      const cartCount = this.container.querySelector('.friendsride-widget-cart-count');
      const cartButton = this.container.querySelector('.friendsride-widget-cart-button');
      
      if (cartCount) {
        cartCount.textContent = this.cart.length;
      }
      if (cartButton) {
        cartButton.textContent = `Vezi coș (${this.getCartTotal().toFixed(2)} RON)`;
      }
    }

    /**
     * Show cart
     */
    showCart() {
      // TODO: Implement cart modal
      alert(`Coș: ${this.cart.length} produse, Total: ${this.getCartTotal().toFixed(2)} RON`);
    }

    /**
     * Inject widget styles
     */
    injectStyles() {
      if (document.getElementById('friendsride-widget-styles')) {
        return;
      }

      const style = document.createElement('style');
      style.id = 'friendsride-widget-styles';
      style.textContent = `
        .friendsride-widget {
          font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif;
          border: 1px solid #e0e0e0;
          border-radius: 12px;
          overflow: hidden;
          max-width: 400px;
          background: white;
        }

        .friendsride-widget-header {
          background: #1976d2;
          color: white;
          padding: 16px;
          display: flex;
          justify-content: space-between;
          align-items: center;
        }

        .friendsride-widget-header h3 {
          margin: 0;
          font-size: 18px;
        }

        .friendsride-widget-close {
          background: none;
          border: none;
          color: white;
          font-size: 24px;
          cursor: pointer;
          padding: 0;
          width: 24px;
          height: 24px;
        }

        .friendsride-widget-content {
          max-height: 500px;
          overflow-y: auto;
          padding: 16px;
        }

        .friendsride-widget-category {
          margin-bottom: 24px;
        }

        .friendsride-widget-category h4 {
          margin: 0 0 12px 0;
          font-size: 16px;
          color: #333;
        }

        .friendsride-widget-product {
          display: flex;
          gap: 12px;
          padding: 12px;
          border: 1px solid #e0e0e0;
          border-radius: 8px;
          margin-bottom: 12px;
        }

        .friendsride-widget-product img {
          width: 80px;
          height: 80px;
          object-fit: cover;
          border-radius: 8px;
        }

        .friendsride-widget-product-info {
          flex: 1;
        }

        .friendsride-widget-product-info h5 {
          margin: 0 0 4px 0;
          font-size: 14px;
        }

        .friendsride-widget-product-info p {
          margin: 0 0 8px 0;
          font-size: 12px;
          color: #666;
        }

        .friendsride-widget-product-footer {
          display: flex;
          justify-content: space-between;
          align-items: center;
        }

        .friendsride-widget-product-price {
          font-weight: bold;
          color: #4caf50;
        }

        .friendsride-widget-add-button {
          background: #1976d2;
          color: white;
          border: none;
          padding: 6px 12px;
          border-radius: 4px;
          cursor: pointer;
          font-size: 12px;
        }

        .friendsride-widget-add-button:hover {
          background: #1565c0;
        }

        .friendsride-widget-footer {
          padding: 16px;
          background: #f5f5f5;
          border-top: 1px solid #e0e0e0;
        }

        .friendsride-widget-cart {
          display: flex;
          align-items: center;
          gap: 12px;
        }

        .friendsride-widget-cart-count {
          background: #1976d2;
          color: white;
          border-radius: 50%;
          width: 24px;
          height: 24px;
          display: flex;
          align-items: center;
          justify-content: center;
          font-size: 12px;
          font-weight: bold;
        }

        .friendsride-widget-cart-button {
          flex: 1;
          background: #4caf50;
          color: white;
          border: none;
          padding: 12px;
          border-radius: 8px;
          cursor: pointer;
          font-size: 14px;
          font-weight: bold;
        }

        .friendsride-widget-cart-button:hover {
          background: #45a049;
        }

        [data-theme="dark"] .friendsride-widget {
          background: #1e1e1e;
          color: white;
        }

        [data-theme="dark"] .friendsride-widget-content {
          background: #1e1e1e;
        }
      `;

      document.head.appendChild(style);
    }
  }

  // Auto-initialize from data attributes
  function autoInit() {
    const containers = document.querySelectorAll('[id^="friendsride-widget"], [data-friendsride-widget]');
    
    containers.forEach(container => {
      const restaurantId = container.getAttribute('data-restaurant-id') || 
                          container.getAttribute('data-friendsride-restaurant-id');
      
      if (restaurantId) {
        const config = {
          restaurantId: restaurantId,
          containerId: container.id || 'friendsride-widget',
          theme: container.getAttribute('data-theme') || 'light',
          language: container.getAttribute('data-language') || 'ro',
          apiKey: container.getAttribute('data-api-key'),
        };

        window.friendsrideWidget = new FriendsRideWidget(config);
      }
    });
  }

  // Initialize when DOM is ready
  if (document.readyState === 'loading') {
    document.addEventListener('DOMContentLoaded', autoInit);
  } else {
    autoInit();
  }

  // Export for manual initialization
  window.FriendsRideWidget = FriendsRideWidget;

})();

