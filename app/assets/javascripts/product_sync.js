window.switchStore = function() {
  const shopDomain = prompt('Enter store domain (e.g., store.myshopify.com):');
  if (shopDomain) {
    const formattedDomain = formatShopifyDomain(shopDomain);
    if (validateShopifyDomain(formattedDomain)) {
      const switchButton = document.querySelector('.current-store');
      const originalText = switchButton.innerHTML;
      switchButton.innerHTML = 'Switching...';
      switchButton.disabled = true;

      window.location.href = '/auth/install?shop=' + encodeURIComponent(formattedDomain);
    } else {
      alert('Please enter a valid Shopify domain (e.g., store.myshopify.com)');
    }
  }
};

function formatShopifyDomain(domain) {
  domain = domain.replace(/^https?:\/\//, '');

  domain = domain.replace(/\/$/, '');

  if (!domain.includes('.myshopify.com')) {
    domain = domain + '.myshopify.com';
  }

  return domain.toLowerCase();
}

function validateShopifyDomain(domain) {
  const pattern = /^[a-zA-Z0-9][a-zA-Z0-9-]*[a-zA-Z0-9]\.myshopify\.com$/;
  return pattern.test(domain);
}

document.addEventListener('DOMContentLoaded', function() {
  const selectAll = document.getElementById('selectAll');
  const productCheckboxes = document.querySelectorAll('.product-checkbox');
  const syncButton = document.getElementById('syncButton');
  const targetStore = document.getElementById('targetStore');
  const spinner = document.createElement('span');
  spinner.className = 'spinner hidden';
  syncButton.prepend(spinner);

  function updateSyncButton() {
    const hasSelectedProducts = Array.from(productCheckboxes).some(cb => cb.checked);
    const hasTargetStore = targetStore.value !== '';
    syncButton.disabled = !hasSelectedProducts || !hasTargetStore;
  }

  selectAll.addEventListener('change', function() {
    productCheckboxes.forEach(cb => cb.checked = this.checked);
    updateSyncButton();
  });

  productCheckboxes.forEach(cb => {
    cb.addEventListener('change', function() {
      selectAll.checked = Array.from(productCheckboxes).every(cb => cb.checked);
      updateSyncButton();
    });
  });

  targetStore.addEventListener('change', updateSyncButton);

  syncButton.addEventListener('click', function() {
    const selectedProducts = Array.from(productCheckboxes)
      .filter(cb => cb.checked)
      .map(cb => cb.value);

    spinner.classList.remove('hidden');
    syncButton.disabled = true;

    fetch('/products/sync', {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        'X-CSRF-Token': document.querySelector('[name="csrf-token"]').content
      },
      body: JSON.stringify({
        product_ids: selectedProducts,
        target_shop_id: targetStore.value
      })
    })
    .then(response => {
      if (!response.ok) {
        throw new Error('Network response was not ok');
      }
      return response.json();
    })
    .then(data => {
      spinner.classList.add('hidden');
      syncButton.disabled = false;
      if (data.status === 'success') {
        const popup = document.getElementById('successPopup');
        popup.classList.add('show');

        selectAll.checked = false;
        productCheckboxes.forEach(cb => cb.checked = false);
        updateSyncButton();

        setTimeout(() => {
          popup.classList.remove('show');
        }, 3000);
      } else {
        alert('Error: ' + data.message);
      }
    })
    .catch(error => {
      spinner.classList.add('hidden');
      syncButton.disabled = false;
      console.error('Error:', error);
      alert('An error occurred while syncing products. Please try again.');
    });
  });
});