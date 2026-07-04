package com.ecommerce.product.repository;

import org.springframework.data.jpa.repository.JpaRepository;

import com.ecommerce.product.model.Product;

public interface ProductRepository extends JpaRepository<Product, Long> {
    // That's it. Extending JpaRepository gives us
    // save(), findById(), findAll(), deleteById(), etc. for free.
}