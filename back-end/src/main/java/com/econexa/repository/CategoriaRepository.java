// backend/src/main/java/com/econexa/repository/CategoriaRepository.java
package com.econexa.repository;

import com.econexa.model.Categoria;
import com.econexa.model.enums.TipoCategoria;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.UUID;

@Repository
public interface CategoriaRepository extends JpaRepository<Categoria, UUID> {
    List<Categoria> findByTipo(TipoCategoria tipo);
    List<Categoria> findByAtivoTrueOrderByOrdemAsc();
}