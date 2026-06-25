# KFE System Treasury Wallet Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add a server-owned KFE system treasury wallet that is bootstrapped on startup, hidden from user wallet surfaces, explicitly counted in reserve overview, and protected by quorum-only transaction flow.

**Architecture:** Keep KFE wallets tied to `user_id`, but create a locked auth principal named `KFE_TREASURY_SYSTEM` and mark the wallet with `system_role = TREASURY`. User-facing wallet and transaction paths must reject system-role wallets; internal bootstrap and reserve services use repository methods that identify the treasury wallet by marker, not by label.

**Tech Stack:** Java 21, Spring Boot 3.5, Spring Data JPA, Flyway SQL migrations, JUnit 5, Mockito, Gradle multi-module backend.

---

## File Structure

Create:

- `backend/kerosene/src/main/resources/db/migration/V30__kfe_system_treasury_wallet.sql` - adds auth `system_account`, wallet `system_role`, uniqueness, and dashboard filtering.
- `backend/kerosene/src/test/java/source/architecture/KfeSystemTreasuryWalletMigrationTest.java` - guards the new migration contract.
- `backend/kerosene/kerosene-contracts/src/main/java/source/common/financial/FinancialSystemPrincipalPort.java` - KFE-facing port for ensuring the technical principal without depending on auth implementation.
- `backend/kerosene/src/main/java/source/auth/integration/AuthFinancialSystemPrincipalAdapter.java` - auth implementation of the technical principal port.
- `backend/kerosene/src/test/java/source/auth/integration/AuthFinancialSystemPrincipalAdapterTest.java` - verifies the technical principal is locked and idempotent.
- `backend/kerosene/kfe-service/src/main/java/source/kfe/model/KfeWalletSystemRole.java` - enum for `TREASURY`.
- `backend/kerosene/kfe-service/src/main/java/source/kfe/service/KfeSystemTreasuryWalletBootstrapper.java` - startup component that guarantees the wallet and balance.
- `backend/kerosene/kfe-service/src/test/java/source/kfe/service/KfeSystemTreasuryWalletBootstrapperTest.java` - bootstrap unit tests.
- `backend/kerosene/kfe-service/src/test/java/source/kfe/service/KfeReserveOverviewServiceTest.java` - reserve overview unit tests.

Modify:

- `backend/kerosene/src/main/java/source/auth/model/entity/UserDataBase.java` - add `systemAccount` field.
- `backend/kerosene/src/main/java/source/auth/application/service/authentication/login/LoginCredentialRules.java` - block login for system accounts.
- `backend/kerosene/src/test/java/source/auth/application/service/authentication/LoginValidatorTest.java` - cover login blocking.
- `backend/kerosene/kfe-service/src/main/java/source/kfe/model/KfeWalletEntity.java` - add `systemRole` field.
- `backend/kerosene/kfe-service/src/main/java/source/kfe/repository/KfeWalletRepository.java` - add system-role-safe query methods.
- `backend/kerosene/kfe-service/src/main/java/source/kfe/repository/KfeBalanceRepository.java` - add a projection/query for treasury balance totals.
- `backend/kerosene/kfe-service/src/main/java/source/kfe/service/KfeBalanceService.java` - add idempotent balance ensure method.
- `backend/kerosene/kfe-service/src/main/java/source/kfe/service/KfeWalletService.java` - add internal creation method that marks treasury wallet and uses existing quorum creation flow.
- `backend/kerosene/kfe-service/src/main/java/source/kfe/service/KfeDashboardService.java` - keep dashboard query on the filtered view.
- `backend/kerosene/kfe-service/src/main/java/source/kfe/service/KfeReserveOverviewService.java` - expose treasury-specific totals.
- `backend/kerosene/kfe-service/src/main/java/source/kfe/dto/KfeReserveOverviewResponse.java` - add treasury fields.
- `backend/kerosene/kfe-service/src/main/java/source/kfe/application/transaction/KfeTransactionWalletResolver.java` - reject system wallets in user-facing source/destination paths.
- `backend/kerosene/kfe-service/src/test/java/source/kfe/service/KfeWalletServiceTest.java` - cover system treasury creation marking and list filtering.
- `backend/kerosene/kfe-service/src/test/java/source/kfe/application/transaction/KfeTransactionWalletResolverTest.java` - cover rejection of system wallets by user transaction flow.
- `backend/kerosene/kfe-service/src/test/java/source/kfe/application/transaction/KfeSubmitTransactionUseCaseTest.java` - preserve proof that submit path requires quorum before locking funds.

---

### Task 1: Schema And Entity Markers

**Files:**
- Create: `backend/kerosene/src/main/resources/db/migration/V30__kfe_system_treasury_wallet.sql`
- Create: `backend/kerosene/src/test/java/source/architecture/KfeSystemTreasuryWalletMigrationTest.java`
- Create: `backend/kerosene/kfe-service/src/main/java/source/kfe/model/KfeWalletSystemRole.java`
- Modify: `backend/kerosene/src/main/java/source/auth/model/entity/UserDataBase.java`
- Modify: `backend/kerosene/kfe-service/src/main/java/source/kfe/model/KfeWalletEntity.java`

- [ ] **Step 1: Write the failing migration guard**

Create `backend/kerosene/src/test/java/source/architecture/KfeSystemTreasuryWalletMigrationTest.java`:

```java
package source.architecture;

import org.junit.jupiter.api.Test;

import java.io.IOException;
import java.nio.file.Files;
import java.nio.file.Path;

import static org.junit.jupiter.api.Assertions.assertTrue;

class KfeSystemTreasuryWalletMigrationTest {

    private static final Path PROJECT_ROOT = Path.of("").toAbsolutePath();
    private static final Path V30_MIGRATION = PROJECT_ROOT.resolve(
            "src/main/resources/db/migration/V30__kfe_system_treasury_wallet.sql");

    @Test
    void systemTreasuryWalletMigrationAddsMarkersAndHidesWalletFromUserDashboard() throws IOException {
        String migration = Files.readString(V30_MIGRATION);

        assertTrue(migration.contains("ADD COLUMN IF NOT EXISTS system_account BOOLEAN NOT NULL DEFAULT FALSE"));
        assertTrue(migration.contains("ADD COLUMN IF NOT EXISTS system_role VARCHAR(32)"));
        assertTrue(migration.contains("chk_wallets_core_system_role"));
        assertTrue(migration.contains("ux_wallets_core_active_system_treasury"));
        assertTrue(migration.contains("WHERE system_role = 'TREASURY'"));
        assertTrue(migration.contains("w.system_role IS NULL"));
        assertAppearsBefore(migration,
                "ADD COLUMN IF NOT EXISTS system_role VARCHAR(32)",
                "CREATE UNIQUE INDEX IF NOT EXISTS ux_wallets_core_active_system_treasury");
        assertAppearsBefore(migration,
                "CREATE UNIQUE INDEX IF NOT EXISTS ux_wallets_core_active_system_treasury",
                "CREATE OR REPLACE VIEW financial.wallet_dashboard_view");
    }

    private static void assertAppearsBefore(String text, String earlier, String later) {
        int earlierIndex = text.indexOf(earlier);
        int laterIndex = text.indexOf(later);

        assertTrue(earlierIndex >= 0, () -> "Missing expected SQL: " + earlier);
        assertTrue(laterIndex >= 0, () -> "Missing expected SQL: " + later);
        assertTrue(earlierIndex < laterIndex, () -> earlier + " must appear before " + later);
    }
}
```

- [ ] **Step 2: Run the migration guard and verify it fails**

Run:

```bash
cd backend/kerosene
JAVA_HOME=/usr/lib/jvm/java-21-openjdk ./gradlew test --tests source.architecture.KfeSystemTreasuryWalletMigrationTest
```

Expected: FAIL because `V30__kfe_system_treasury_wallet.sql` does not exist.

- [ ] **Step 3: Add the Flyway migration**

Create `backend/kerosene/src/main/resources/db/migration/V30__kfe_system_treasury_wallet.sql`:

```sql
ALTER TABLE auth.users_credentials
    ADD COLUMN IF NOT EXISTS system_account BOOLEAN NOT NULL DEFAULT FALSE;

ALTER TABLE financial.wallets_core
    ADD COLUMN IF NOT EXISTS system_role VARCHAR(32);

DO $$
BEGIN
    ALTER TABLE financial.wallets_core
        ADD CONSTRAINT chk_wallets_core_system_role
        CHECK (system_role IS NULL OR system_role IN ('TREASURY'));
EXCEPTION
    WHEN duplicate_object THEN
        NULL;
END $$;

CREATE UNIQUE INDEX IF NOT EXISTS ux_wallets_core_active_system_treasury
    ON financial.wallets_core(system_role)
    WHERE system_role = 'TREASURY'
      AND status IN ('CREATING', 'ACTIVE', 'FROZEN', 'ROTATING_ADDRESS');

CREATE INDEX IF NOT EXISTS idx_wallets_core_system_role_status
    ON financial.wallets_core(system_role, status)
    WHERE system_role IS NOT NULL;

CREATE OR REPLACE VIEW financial.wallet_dashboard_view AS
SELECT
    w.id AS wallet_id,
    w.user_id,
    w.kind,
    w.status,
    w.label,
    w.asset,
    w.spendable,
    COALESCE(b.available_sats, 0) AS available_sats,
    COALESCE(b.pending_sats, 0) AS pending_sats,
    COALESCE(b.locked_sats, 0) AS locked_sats,
    COALESCE(b.auto_hold_sats, 0) AS auto_hold_sats,
    COALESCE(b.observed_sats, 0) AS observed_sats,
    (
        SELECT a.address
        FROM financial.wallet_addresses a
        WHERE a.wallet_id = w.id AND a.status = 'ACTIVE'
        ORDER BY a.created_at DESC
        LIMIT 1
    ) AS active_address,
    w.created_at,
    w.updated_at
FROM financial.wallets_core w
LEFT JOIN financial.balances_core b
    ON b.wallet_id = w.id AND b.asset = w.asset
WHERE w.status IN ('CREATING', 'ACTIVE', 'FROZEN', 'ROTATING_ADDRESS')
  AND w.system_role IS NULL;
```

- [ ] **Step 4: Add the KFE wallet system role enum**

Create `backend/kerosene/kfe-service/src/main/java/source/kfe/model/KfeWalletSystemRole.java`:

```java
package source.kfe.model;

public enum KfeWalletSystemRole {
    TREASURY
}
```

- [ ] **Step 5: Add `systemAccount` to `UserDataBase`**

Modify `backend/kerosene/src/main/java/source/auth/model/entity/UserDataBase.java`.

Add the field after `role`:

```java
    @Column(name = "system_account", nullable = false, columnDefinition = "boolean default false")
    private Boolean systemAccount = false;
```

Add getters/setters after `setRole(...)`:

```java
    public Boolean getSystemAccount() {
        return systemAccount;
    }

    public void setSystemAccount(Boolean systemAccount) {
        this.systemAccount = systemAccount != null ? systemAccount : false;
    }
```

- [ ] **Step 6: Add `systemRole` to `KfeWalletEntity`**

Modify `backend/kerosene/kfe-service/src/main/java/source/kfe/model/KfeWalletEntity.java`.

Add imports if missing:

```java
import jakarta.persistence.EnumType;
import jakarta.persistence.Enumerated;
```

Add the field after `spendable`:

```java
    @Enumerated(EnumType.STRING)
    @Column(name = "system_role", length = 32)
    private KfeWalletSystemRole systemRole;
```

Add getters/setters after `setSpendable(...)`:

```java
    public KfeWalletSystemRole getSystemRole() {
        return systemRole;
    }

    public void setSystemRole(KfeWalletSystemRole systemRole) {
        this.systemRole = systemRole;
    }
```

- [ ] **Step 7: Run the migration guard and module compile**

Run:

```bash
cd backend/kerosene
JAVA_HOME=/usr/lib/jvm/java-21-openjdk ./gradlew test --tests source.architecture.KfeSystemTreasuryWalletMigrationTest :kfe-service:compileJava compileJava
```

Expected: PASS.

- [ ] **Step 8: Commit Task 1**

```bash
git add \
  backend/kerosene/src/main/resources/db/migration/V30__kfe_system_treasury_wallet.sql \
  backend/kerosene/src/test/java/source/architecture/KfeSystemTreasuryWalletMigrationTest.java \
  backend/kerosene/kfe-service/src/main/java/source/kfe/model/KfeWalletSystemRole.java \
  backend/kerosene/src/main/java/source/auth/model/entity/UserDataBase.java \
  backend/kerosene/kfe-service/src/main/java/source/kfe/model/KfeWalletEntity.java
git commit -m "feat: add KFE system treasury markers"
```

---

### Task 2: Locked Technical Principal

**Files:**
- Create: `backend/kerosene/kerosene-contracts/src/main/java/source/common/financial/FinancialSystemPrincipalPort.java`
- Create: `backend/kerosene/src/main/java/source/auth/integration/AuthFinancialSystemPrincipalAdapter.java`
- Create: `backend/kerosene/src/test/java/source/auth/integration/AuthFinancialSystemPrincipalAdapterTest.java`
- Modify: `backend/kerosene/src/main/java/source/auth/application/service/authentication/login/LoginCredentialRules.java`
- Modify: `backend/kerosene/src/test/java/source/auth/application/service/authentication/LoginValidatorTest.java`

- [ ] **Step 1: Write failing technical-principal adapter tests**

Create `backend/kerosene/src/test/java/source/auth/integration/AuthFinancialSystemPrincipalAdapterTest.java`:

```java
package source.auth.integration;

import org.junit.jupiter.api.Test;
import source.auth.application.infra.persistence.jpa.UserRepository;
import source.auth.model.entity.UserDataBase;
import source.common.financial.FinancialSystemPrincipalPort;

import java.lang.reflect.Field;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertFalse;
import static org.junit.jupiter.api.Assertions.assertSame;
import static org.junit.jupiter.api.Assertions.assertTrue;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

class AuthFinancialSystemPrincipalAdapterTest {

    private static final String USERNAME = "KFE_TREASURY_SYSTEM";

    private final UserRepository repository = mock(UserRepository.class);
    private final AuthFinancialSystemPrincipalAdapter adapter = new AuthFinancialSystemPrincipalAdapter(repository);

    @Test
    void ensureSystemPrincipalCreatesLockedSystemAccountWhenMissing() {
        when(repository.findByUsername(USERNAME)).thenReturn(null);
        when(repository.save(any(UserDataBase.class))).thenAnswer(invocation -> {
            UserDataBase user = invocation.getArgument(0);
            setUserId(user, 77L);
            return user;
        });

        FinancialSystemPrincipalPort.SystemPrincipal principal = adapter.ensureSystemPrincipal(USERNAME);

        assertEquals(77L, principal.id());
        assertEquals(USERNAME, principal.username());
        verify(repository).save(org.mockito.ArgumentMatchers.argThat(user ->
                USERNAME.equals(user.getUsername())
                        && Boolean.TRUE.equals(user.getSystemAccount())
                        && Boolean.FALSE.equals(user.getIsActive())
                        && user.getPasswordHash() != null
                        && user.getPlatformCosignerSecret() == null
                        && user.getTOTPSecret() == null));
    }

    @Test
    void ensureSystemPrincipalReturnsExistingSystemAccount() {
        UserDataBase existing = new UserDataBase();
        setUserId(existing, 88L);
        existing.setUsername(USERNAME);
        existing.setSystemAccount(true);
        existing.setIsActive(false);
        existing.setPasswordHash("locked");
        when(repository.findByUsername(USERNAME)).thenReturn(existing);

        FinancialSystemPrincipalPort.SystemPrincipal principal = adapter.ensureSystemPrincipal(USERNAME);

        assertEquals(88L, principal.id());
        assertEquals(USERNAME, principal.username());
        verify(repository, org.mockito.Mockito.never()).save(any());
    }

    @Test
    void ensureSystemPrincipalRepairsExistingNonSystemAccountFlags() {
        UserDataBase existing = new UserDataBase();
        setUserId(existing, 89L);
        existing.setUsername(USERNAME);
        existing.setSystemAccount(false);
        existing.setIsActive(true);
        existing.setPasswordHash("human-hash");
        when(repository.findByUsername(USERNAME)).thenReturn(existing);
        when(repository.save(existing)).thenReturn(existing);

        FinancialSystemPrincipalPort.SystemPrincipal principal = adapter.ensureSystemPrincipal(USERNAME);

        assertEquals(89L, principal.id());
        assertTrue(Boolean.TRUE.equals(existing.getSystemAccount()));
        assertFalse(Boolean.TRUE.equals(existing.getIsActive()));
        assertEquals(USERNAME, principal.username());
        verify(repository).save(existing);
    }

    private void setUserId(UserDataBase user, Long id) {
        try {
            Field field = UserDataBase.class.getDeclaredField("id");
            field.setAccessible(true);
            field.set(user, id);
        } catch (ReflectiveOperationException exception) {
            throw new RuntimeException(exception);
        }
    }
}
```

- [ ] **Step 2: Add failing login-block test**

Modify `backend/kerosene/src/test/java/source/auth/application/service/authentication/LoginValidatorTest.java`.

Add this test after `matcherWithoutDeviceShouldRejectWhenRateLimitIsExceeded()`:

```java
    @Test
    void matcherWithoutDeviceShouldRejectSystemAccountsBeforePassphraseVerification() {
        UserDTO dto = new UserDTO();
        dto.setUsername("KFE_TREASURY_SYSTEM");
        dto.setPassphrase("server-only".toCharArray());

        UserDataBase user = new UserDataBase();
        user.setUsername("KFE_TREASURY_SYSTEM");
        user.setSystemAccount(true);
        user.setPassphrase("stored-hash");

        when(redisService.increment("rl:login:kfe_treasury_system")).thenReturn(1L);
        when(userGateway.findByUsername("kfe_treasury_system")).thenReturn(user);

        assertThrows(AuthExceptions.InvalidCredentials.class, () -> validator.matcherWithoutDevice(dto));

        verify(hasher, never()).verify(any(char[].class), any());
        verify(redisService, never()).deleteValue("rl:login:kfe_treasury_system");
    }
```

- [ ] **Step 3: Run tests and verify they fail**

Run:

```bash
cd backend/kerosene
JAVA_HOME=/usr/lib/jvm/java-21-openjdk ./gradlew test \
  --tests source.auth.integration.AuthFinancialSystemPrincipalAdapterTest \
  --tests source.auth.application.service.authentication.LoginValidatorTest
```

Expected: FAIL because `FinancialSystemPrincipalPort`, `AuthFinancialSystemPrincipalAdapter`, and system-account login blocking are not implemented.

- [ ] **Step 4: Add the shared system-principal port**

Create `backend/kerosene/kerosene-contracts/src/main/java/source/common/financial/FinancialSystemPrincipalPort.java`:

```java
package source.common.financial;

public interface FinancialSystemPrincipalPort {

    SystemPrincipal ensureSystemPrincipal(String username);

    record SystemPrincipal(Long id, String username) {
        public SystemPrincipal {
            if (id == null) {
                throw new IllegalArgumentException("System principal id is required.");
            }
            if (username == null || username.isBlank()) {
                throw new IllegalArgumentException("System principal username is required.");
            }
        }
    }
}
```

- [ ] **Step 5: Implement the auth adapter**

Create `backend/kerosene/src/main/java/source/auth/integration/AuthFinancialSystemPrincipalAdapter.java`:

```java
package source.auth.integration;

import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import source.auth.application.infra.persistence.jpa.UserRepository;
import source.auth.model.entity.UserDataBase;
import source.common.financial.FinancialSystemPrincipalPort;

import java.security.SecureRandom;
import java.util.HexFormat;

@Service
public class AuthFinancialSystemPrincipalAdapter implements FinancialSystemPrincipalPort {

    private static final SecureRandom RANDOM = new SecureRandom();

    private final UserRepository userRepository;

    public AuthFinancialSystemPrincipalAdapter(UserRepository userRepository) {
        this.userRepository = userRepository;
    }

    @Override
    @Transactional
    public SystemPrincipal ensureSystemPrincipal(String username) {
        String normalizedUsername = requireUsername(username);
        UserDataBase user = userRepository.findByUsername(normalizedUsername);
        if (user == null) {
            user = createLockedSystemAccount(normalizedUsername);
        } else if (!Boolean.TRUE.equals(user.getSystemAccount()) || Boolean.TRUE.equals(user.getIsActive())) {
            user.setSystemAccount(true);
            user.setIsActive(false);
            user.setPasswordHash(lockedPasswordHash());
            user.setTOTPSecret(null);
            user.setPlatformCosignerSecret(null);
            user = userRepository.save(user);
        }
        if (user.getId() == null) {
            throw new IllegalStateException("System principal was persisted without an id.");
        }
        return new SystemPrincipal(user.getId(), user.getUsername());
    }

    private UserDataBase createLockedSystemAccount(String username) {
        UserDataBase user = new UserDataBase();
        user.setUsername(username);
        user.setSystemAccount(true);
        user.setIsActive(false);
        user.setPasswordHash(lockedPasswordHash());
        user.setTOTPSecret(null);
        user.setPlatformCosignerSecret(null);
        return userRepository.save(user);
    }

    private String requireUsername(String username) {
        if (username == null || username.isBlank()) {
            throw new IllegalArgumentException("System principal username is required.");
        }
        return username.trim();
    }

    private String lockedPasswordHash() {
        byte[] bytes = new byte[32];
        RANDOM.nextBytes(bytes);
        return "SYSTEM_ACCOUNT_LOCKED:" + HexFormat.of().formatHex(bytes);
    }
}
```

- [ ] **Step 6: Block system-account login**

Modify `backend/kerosene/src/main/java/source/auth/application/service/authentication/login/LoginCredentialRules.java`.

Update `loadUser(...)`:

```java
    public UserDataBase loadUser(String normalizedUsername) {
        UserDataBase user = userGateway.findByUsername(normalizedUsername);
        if (user == null || Boolean.TRUE.equals(user.getSystemAccount())) {
            throw new AuthExceptions.InvalidCredentials(AuthConstants.ERR_INVALID_CREDENTIALS);
        }
        return user;
    }
```

- [ ] **Step 7: Run focused auth tests**

Run:

```bash
cd backend/kerosene
JAVA_HOME=/usr/lib/jvm/java-21-openjdk ./gradlew test \
  --tests source.auth.integration.AuthFinancialSystemPrincipalAdapterTest \
  --tests source.auth.application.service.authentication.LoginValidatorTest
```

Expected: PASS.

- [ ] **Step 8: Commit Task 2**

```bash
git add \
  backend/kerosene/kerosene-contracts/src/main/java/source/common/financial/FinancialSystemPrincipalPort.java \
  backend/kerosene/src/main/java/source/auth/integration/AuthFinancialSystemPrincipalAdapter.java \
  backend/kerosene/src/test/java/source/auth/integration/AuthFinancialSystemPrincipalAdapterTest.java \
  backend/kerosene/src/main/java/source/auth/application/service/authentication/login/LoginCredentialRules.java \
  backend/kerosene/src/test/java/source/auth/application/service/authentication/LoginValidatorTest.java
git commit -m "feat: add locked KFE treasury principal"
```

---

### Task 3: Treasury Wallet Bootstrap

**Files:**
- Create: `backend/kerosene/kfe-service/src/main/java/source/kfe/service/KfeSystemTreasuryWalletBootstrapper.java`
- Create: `backend/kerosene/kfe-service/src/test/java/source/kfe/service/KfeSystemTreasuryWalletBootstrapperTest.java`
- Modify: `backend/kerosene/kfe-service/src/main/java/source/kfe/repository/KfeWalletRepository.java`
- Modify: `backend/kerosene/kfe-service/src/main/java/source/kfe/service/KfeBalanceService.java`
- Modify: `backend/kerosene/kfe-service/src/main/java/source/kfe/service/KfeWalletService.java`
- Modify: `backend/kerosene/kfe-service/src/test/java/source/kfe/service/KfeWalletServiceTest.java`

- [ ] **Step 1: Add failing wallet-service test for system treasury creation**

Modify `backend/kerosene/kfe-service/src/test/java/source/kfe/service/KfeWalletServiceTest.java`.

Add this test after `createWalletForcesInternalLabelToGlobalWallet()`:

```java
    @Test
    void createSystemTreasuryWalletMarksWalletAsTreasuryAndUsesQuorum() {
        AtomicReference<KfeWalletEntity> persistedWallet = new AtomicReference<>();

        when(transactionTemplate.execute(any())).thenAnswer(invocation -> {
            TransactionCallback<?> callback = invocation.getArgument(0);
            return callback.doInTransaction(null);
        });
        when(walletRepository.save(any(KfeWalletEntity.class))).thenAnswer(invocation -> {
            KfeWalletEntity wallet = invocation.getArgument(0);
            persistedWallet.set(wallet);
            return wallet;
        });
        when(hashService.sha256(anyString())).thenReturn("proposal-hash");
        when(quorumGateway.requireHealthyUnanimousConsensus("proposal-hash"))
                .thenReturn(new KfeQuorumGateway.Result(2, 2));
        when(walletRepository.findByIdAndUserIdForUpdate(any(UUID.class), eq(77L)))
                .thenAnswer(invocation -> Optional.ofNullable(persistedWallet.get()));
        when(responseMapper.toWalletResponse(any(KfeWalletEntity.class)))
                .thenAnswer(invocation -> {
                    KfeWalletEntity wallet = invocation.getArgument(0);
                    return new KfeWalletResponse(
                            wallet.getId(),
                            wallet.getKind(),
                            wallet.getStatus(),
                            wallet.getLabel(),
                            wallet.getLabel(),
                            "Carteira Global",
                            "BTC",
                            wallet.isSpendable(),
                            false,
                            true,
                            null,
                            java.time.LocalDateTime.now(),
                            java.time.LocalDateTime.now());
                });

        KfeWalletResponse response = service.createSystemTreasuryWallet(77L);

        assertEquals("carteira global", response.label());
        assertEquals(KfeWalletKind.INTERNAL, persistedWallet.get().getKind());
        assertEquals(KfeWalletSystemRole.TREASURY, persistedWallet.get().getSystemRole());
        verify(quorumGateway).requireHealthyUnanimousConsensus("proposal-hash");
        verifyNoInteractions(mpcKeyService);
    }
```

- [ ] **Step 2: Add failing bootstrap tests**

Create `backend/kerosene/kfe-service/src/test/java/source/kfe/service/KfeSystemTreasuryWalletBootstrapperTest.java`:

```java
package source.kfe.service;

import org.junit.jupiter.api.Test;
import org.springframework.transaction.support.TransactionCallback;
import org.springframework.transaction.support.TransactionTemplate;
import source.common.financial.FinancialSystemPrincipalPort;
import source.kfe.dto.KfeWalletResponse;
import source.kfe.model.KfeWalletEntity;
import source.kfe.model.KfeWalletKind;
import source.kfe.model.KfeWalletStatus;
import source.kfe.model.KfeWalletSystemRole;
import source.kfe.repository.KfeWalletRepository;

import java.time.LocalDateTime;
import java.util.List;
import java.util.UUID;

import static org.junit.jupiter.api.Assertions.assertThrows;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.never;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

class KfeSystemTreasuryWalletBootstrapperTest {

    private final FinancialSystemPrincipalPort principalPort = mock(FinancialSystemPrincipalPort.class);
    private final KfeWalletRepository walletRepository = mock(KfeWalletRepository.class);
    private final KfeWalletService walletService = mock(KfeWalletService.class);
    private final KfeBalanceService balanceService = mock(KfeBalanceService.class);
    private final KfeAuditLogService auditLogService = mock(KfeAuditLogService.class);
    private final TransactionTemplate transactionTemplate = mock(TransactionTemplate.class);

    private final KfeSystemTreasuryWalletBootstrapper bootstrapper = new KfeSystemTreasuryWalletBootstrapper(
            principalPort,
            walletRepository,
            walletService,
            balanceService,
            auditLogService,
            transactionTemplate);

    @Test
    void bootstrapCreatesTreasuryWalletWhenMissing() {
        when(transactionTemplate.execute(any())).thenAnswer(invocation -> {
            TransactionCallback<?> callback = invocation.getArgument(0);
            return callback.doInTransaction(null);
        });
        when(principalPort.ensureSystemPrincipal("KFE_TREASURY_SYSTEM"))
                .thenReturn(new FinancialSystemPrincipalPort.SystemPrincipal(77L, "KFE_TREASURY_SYSTEM"));
        when(walletRepository.findBySystemRoleAndStatusIn(KfeWalletSystemRole.TREASURY,
                KfeSystemTreasuryWalletBootstrapper.ACTIVE_SYSTEM_WALLET_STATUSES))
                .thenReturn(List.of());
        UUID walletId = UUID.randomUUID();
        when(walletService.createSystemTreasuryWallet(77L)).thenReturn(walletResponse(walletId));

        bootstrapper.ensureTreasuryWalletReady();

        verify(walletService).createSystemTreasuryWallet(77L);
        verify(balanceService).ensureBalanceExists(walletId, "BTC");
        verify(auditLogService).record(
                org.mockito.ArgumentMatchers.eq("KFE_SYSTEM_TREASURY_WALLET_BOOTSTRAPPED"),
                org.mockito.ArgumentMatchers.isNull(),
                org.mockito.ArgumentMatchers.eq(walletId),
                org.mockito.ArgumentMatchers.isNull(),
                org.mockito.ArgumentMatchers.isNull(),
                org.mockito.ArgumentMatchers.anyMap());
    }

    @Test
    void bootstrapOnlyRepairsBalanceWhenTreasuryWalletAlreadyExists() {
        when(transactionTemplate.execute(any())).thenAnswer(invocation -> {
            TransactionCallback<?> callback = invocation.getArgument(0);
            return callback.doInTransaction(null);
        });
        when(principalPort.ensureSystemPrincipal("KFE_TREASURY_SYSTEM"))
                .thenReturn(new FinancialSystemPrincipalPort.SystemPrincipal(77L, "KFE_TREASURY_SYSTEM"));
        UUID walletId = UUID.randomUUID();
        KfeWalletEntity existing = wallet(walletId, 77L);
        when(walletRepository.findBySystemRoleAndStatusIn(KfeWalletSystemRole.TREASURY,
                KfeSystemTreasuryWalletBootstrapper.ACTIVE_SYSTEM_WALLET_STATUSES))
                .thenReturn(List.of(existing));

        bootstrapper.ensureTreasuryWalletReady();

        verify(walletService, never()).createSystemTreasuryWallet(any());
        verify(balanceService).ensureBalanceExists(walletId, "BTC");
        verify(auditLogService, never()).record(
                org.mockito.ArgumentMatchers.eq("KFE_SYSTEM_TREASURY_WALLET_BOOTSTRAPPED"),
                org.mockito.ArgumentMatchers.any(),
                org.mockito.ArgumentMatchers.any(),
                org.mockito.ArgumentMatchers.any(),
                org.mockito.ArgumentMatchers.any(),
                org.mockito.ArgumentMatchers.anyMap());
    }

    @Test
    void bootstrapFailsClosedWhenDuplicateTreasuryWalletsExist() {
        when(transactionTemplate.execute(any())).thenAnswer(invocation -> {
            TransactionCallback<?> callback = invocation.getArgument(0);
            return callback.doInTransaction(null);
        });
        when(principalPort.ensureSystemPrincipal("KFE_TREASURY_SYSTEM"))
                .thenReturn(new FinancialSystemPrincipalPort.SystemPrincipal(77L, "KFE_TREASURY_SYSTEM"));
        when(walletRepository.findBySystemRoleAndStatusIn(KfeWalletSystemRole.TREASURY,
                KfeSystemTreasuryWalletBootstrapper.ACTIVE_SYSTEM_WALLET_STATUSES))
                .thenReturn(List.of(wallet(UUID.randomUUID(), 77L), wallet(UUID.randomUUID(), 77L)));

        assertThrows(IllegalStateException.class, bootstrapper::ensureTreasuryWalletReady);

        verify(walletService, never()).createSystemTreasuryWallet(any());
    }

    private KfeWalletEntity wallet(UUID walletId, Long userId) {
        KfeWalletEntity wallet = new KfeWalletEntity();
        wallet.setId(walletId);
        wallet.setUserId(userId);
        wallet.setKind(KfeWalletKind.INTERNAL);
        wallet.setStatus(KfeWalletStatus.ACTIVE);
        wallet.setLabel("carteira global");
        wallet.setSystemRole(KfeWalletSystemRole.TREASURY);
        return wallet;
    }

    private KfeWalletResponse walletResponse(UUID walletId) {
        return new KfeWalletResponse(
                walletId,
                KfeWalletKind.INTERNAL,
                KfeWalletStatus.ACTIVE,
                "carteira global",
                "carteira global",
                "Carteira Global",
                "BTC",
                true,
                false,
                true,
                null,
                LocalDateTime.now(),
                LocalDateTime.now());
    }
}
```

- [ ] **Step 3: Run tests and verify they fail**

Run:

```bash
cd backend/kerosene
JAVA_HOME=/usr/lib/jvm/java-21-openjdk ./gradlew :kfe-service:test \
  --tests source.kfe.service.KfeWalletServiceTest \
  --tests source.kfe.service.KfeSystemTreasuryWalletBootstrapperTest
```

Expected: FAIL because `createSystemTreasuryWallet`, repository methods, and bootstrapper are missing.

- [ ] **Step 4: Add repository methods**

Modify `backend/kerosene/kfe-service/src/main/java/source/kfe/repository/KfeWalletRepository.java`.

Add import:

```java
import source.kfe.model.KfeWalletSystemRole;
```

Add methods:

```java
    List<KfeWalletEntity> findBySystemRoleAndStatusIn(
            KfeWalletSystemRole systemRole,
            Collection<KfeWalletStatus> statuses);

    List<KfeWalletEntity> findByUserIdAndStatusInAndSystemRoleIsNullOrderByCreatedAtDesc(
            Long userId,
            Collection<KfeWalletStatus> statuses);
```

- [ ] **Step 5: Add idempotent balance ensure**

Modify `backend/kerosene/kfe-service/src/main/java/source/kfe/service/KfeBalanceService.java`.

Add import:

```java
import org.springframework.transaction.annotation.Transactional;
```

Add method after `createEmptyBalance(...)`:

```java
    @Transactional
    public KfeBalanceEntity ensureBalanceExists(UUID walletId, String asset) {
        String normalizedAsset = asset != null ? asset : "BTC";
        KfeBalanceId id = new KfeBalanceId(walletId, normalizedAsset);
        return balanceRepository.findById(id)
                .orElseGet(() -> createEmptyBalance(walletId, normalizedAsset));
    }
```

- [ ] **Step 6: Add system treasury creation to wallet service**

Modify `backend/kerosene/kfe-service/src/main/java/source/kfe/service/KfeWalletService.java`.

Add import:

```java
import source.kfe.model.KfeWalletSystemRole;
```

Add public method after `createWallet(...)`:

```java
    public KfeWalletResponse createSystemTreasuryWallet(Long userId) {
        KfeCreateWalletRequest request = new KfeCreateWalletRequest(
                KfeWalletKind.INTERNAL,
                null,
                INTERNAL_GLOBAL_WALLET_LABEL,
                null,
                null,
                null,
                null,
                null,
                null,
                null,
                null,
                false);

        PendingWallet pending = Objects.requireNonNull(transactionTemplate.execute(status ->
                createPendingWallet(userId, request, KfeWalletSystemRole.TREASURY)));
        String proposalHash = kfeWalletCreateProposalHash(userId, pending);
        KfeQuorumGateway.Result quorum = requireWalletCreateQuorum(userId, pending, proposalHash);

        try {
            return Objects.requireNonNull(transactionTemplate.execute(status ->
                    activateWallet(userId, request, pending.walletId(), proposalHash, quorum, null)));
        } catch (RuntimeException exception) {
            markWalletCreationFailed(
                    userId,
                    pending.walletId(),
                    KfeWalletStatus.KEYGEN_FAILED,
                    "System treasury wallet activation failed: " + safeReason(exception));
            throw exception;
        }
    }
```

Change the existing `createPendingWallet(userId, request)` call inside `createWallet(...)` to:

```java
                createPendingWallet(userId, request, null)));
```

Change the `createPendingWallet` signature and body:

```java
    private PendingWallet createPendingWallet(
            Long userId,
            KfeCreateWalletRequest request,
            KfeWalletSystemRole systemRole) {
        requireWalletCapacity(userId, request.kind());
        KfeWalletEntity wallet = new KfeWalletEntity();
        wallet.setUserId(userId);
        wallet.setKind(request.kind());
        wallet.setSystemRole(systemRole);
        wallet.setStatus(KfeWalletStatus.CREATING);
```

Keep the rest of the existing method body unchanged.

- [ ] **Step 7: Implement the bootstrapper**

Create `backend/kerosene/kfe-service/src/main/java/source/kfe/service/KfeSystemTreasuryWalletBootstrapper.java`:

```java
package source.kfe.service;

import org.springframework.boot.context.event.ApplicationReadyEvent;
import org.springframework.context.event.EventListener;
import org.springframework.stereotype.Component;
import org.springframework.transaction.support.TransactionTemplate;
import source.common.financial.FinancialSystemPrincipalPort;
import source.kfe.dto.KfeWalletResponse;
import source.kfe.model.KfeWalletEntity;
import source.kfe.model.KfeWalletStatus;
import source.kfe.model.KfeWalletSystemRole;
import source.kfe.repository.KfeWalletRepository;

import java.util.List;
import java.util.Map;
import java.util.UUID;

@Component
public class KfeSystemTreasuryWalletBootstrapper {

    static final String SYSTEM_PRINCIPAL_USERNAME = "KFE_TREASURY_SYSTEM";
    static final String ASSET_BTC = "BTC";
    static final List<KfeWalletStatus> ACTIVE_SYSTEM_WALLET_STATUSES = List.of(
            KfeWalletStatus.CREATING,
            KfeWalletStatus.ACTIVE,
            KfeWalletStatus.FROZEN,
            KfeWalletStatus.ROTATING_ADDRESS);

    private final FinancialSystemPrincipalPort principalPort;
    private final KfeWalletRepository walletRepository;
    private final KfeWalletService walletService;
    private final KfeBalanceService balanceService;
    private final KfeAuditLogService auditLogService;
    private final TransactionTemplate transactionTemplate;

    public KfeSystemTreasuryWalletBootstrapper(
            FinancialSystemPrincipalPort principalPort,
            KfeWalletRepository walletRepository,
            KfeWalletService walletService,
            KfeBalanceService balanceService,
            KfeAuditLogService auditLogService,
            TransactionTemplate transactionTemplate) {
        this.principalPort = principalPort;
        this.walletRepository = walletRepository;
        this.walletService = walletService;
        this.balanceService = balanceService;
        this.auditLogService = auditLogService;
        this.transactionTemplate = transactionTemplate;
    }

    @EventListener(ApplicationReadyEvent.class)
    public void onApplicationReady() {
        ensureTreasuryWalletReady();
    }

    public void ensureTreasuryWalletReady() {
        transactionTemplate.executeWithoutResult(status -> {
            FinancialSystemPrincipalPort.SystemPrincipal principal =
                    principalPort.ensureSystemPrincipal(SYSTEM_PRINCIPAL_USERNAME);
            List<KfeWalletEntity> wallets = walletRepository.findBySystemRoleAndStatusIn(
                    KfeWalletSystemRole.TREASURY,
                    ACTIVE_SYSTEM_WALLET_STATUSES);
            if (wallets.size() > 1) {
                throw new IllegalStateException("Multiple active KFE system treasury wallets found.");
            }
            if (wallets.size() == 1) {
                balanceService.ensureBalanceExists(wallets.get(0).getId(), ASSET_BTC);
                return;
            }

            KfeWalletResponse created = walletService.createSystemTreasuryWallet(principal.id());
            UUID walletId = created.id();
            balanceService.ensureBalanceExists(walletId, ASSET_BTC);
            auditLogService.record(
                    "KFE_SYSTEM_TREASURY_WALLET_BOOTSTRAPPED",
                    null,
                    walletId,
                    null,
                    null,
                    Map.of(
                            "walletId", walletId.toString(),
                            "systemPrincipal", principal.username(),
                            "systemRole", KfeWalletSystemRole.TREASURY.name()));
        });
    }
}
```

- [ ] **Step 8: Run focused bootstrap tests**

Run:

```bash
cd backend/kerosene
JAVA_HOME=/usr/lib/jvm/java-21-openjdk ./gradlew :kfe-service:test \
  --tests source.kfe.service.KfeWalletServiceTest \
  --tests source.kfe.service.KfeSystemTreasuryWalletBootstrapperTest
```

Expected: PASS.

- [ ] **Step 9: Commit Task 3**

```bash
git add \
  backend/kerosene/kfe-service/src/main/java/source/kfe/service/KfeSystemTreasuryWalletBootstrapper.java \
  backend/kerosene/kfe-service/src/test/java/source/kfe/service/KfeSystemTreasuryWalletBootstrapperTest.java \
  backend/kerosene/kfe-service/src/main/java/source/kfe/repository/KfeWalletRepository.java \
  backend/kerosene/kfe-service/src/main/java/source/kfe/service/KfeBalanceService.java \
  backend/kerosene/kfe-service/src/main/java/source/kfe/service/KfeWalletService.java \
  backend/kerosene/kfe-service/src/test/java/source/kfe/service/KfeWalletServiceTest.java
git commit -m "feat: bootstrap KFE system treasury wallet"
```

---

### Task 4: Hide Treasury Wallet From User Surfaces

**Files:**
- Modify: `backend/kerosene/kfe-service/src/main/java/source/kfe/service/KfeWalletService.java`
- Modify: `backend/kerosene/kfe-service/src/main/java/source/kfe/application/transaction/KfeTransactionWalletResolver.java`
- Modify: `backend/kerosene/kfe-service/src/test/java/source/kfe/service/KfeWalletServiceTest.java`
- Modify: `backend/kerosene/kfe-service/src/test/java/source/kfe/application/transaction/KfeTransactionWalletResolverTest.java`

- [ ] **Step 1: Add failing wallet-list filtering assertion**

Modify `backend/kerosene/kfe-service/src/test/java/source/kfe/service/KfeWalletServiceTest.java`.

Update `listWalletsReturnsMappedResponses()` so the repository expectation uses the new null-system-role method:

```java
        when(walletRepository.findByUserIdAndStatusInAndSystemRoleIsNullOrderByCreatedAtDesc(eq(1L), any()))
                .thenReturn(List.of(wallet));
```

Update the verification:

```java
        verify(walletRepository).findByUserIdAndStatusInAndSystemRoleIsNullOrderByCreatedAtDesc(eq(1L), any());
```

- [ ] **Step 2: Add failing transaction resolver tests**

Modify `backend/kerosene/kfe-service/src/test/java/source/kfe/application/transaction/KfeTransactionWalletResolverTest.java`.

Add these tests:

```java
    @Test
    void resolveSourceWalletRejectsSystemTreasuryWalletInUserFlow() {
        UUID walletId = UUID.randomUUID();
        KfeWalletEntity wallet = activeWallet(walletId, 42L);
        wallet.setSystemRole(KfeWalletSystemRole.TREASURY);
        when(walletRepository.findByIdAndUserIdForUpdate(walletId, 42L)).thenReturn(Optional.of(wallet));

        IllegalStateException exception = assertThrows(
                IllegalStateException.class,
                () -> resolver.resolveSourceWallet(42L, outboundRequest(walletId)));

        assertEquals("source wallet is a system treasury wallet and is not available through user transaction flow.",
                exception.getMessage());
    }

    @Test
    void resolveDestinationReferenceIgnoresSystemTreasuryWalletsAndInactiveUsers() {
        when(userDirectory.findByUsername("kfe_treasury_system"))
                .thenReturn(Optional.of(new FinancialUserDirectoryPort.FinancialUserHandle(
                        77L,
                        "KFE_TREASURY_SYSTEM",
                        false)));

        IllegalArgumentException exception = assertThrows(
                IllegalArgumentException.class,
                () -> resolver.resolveInternalDestinationReference(internalReferenceRequest("@kfe_treasury_system")));

        assertEquals("Destination user is not active.", exception.getMessage());
        verify(walletRepository, never()).findByUserIdOrderByCreatedAtDesc(any());
    }
```

Add helper imports if missing:

```java
import source.kfe.model.KfeWalletSystemRole;
import java.util.Optional;
import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertThrows;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.never;
```

Use existing helper methods in the test class when names already differ; keep the assertions above unchanged.

- [ ] **Step 3: Run tests and verify they fail**

Run:

```bash
cd backend/kerosene
JAVA_HOME=/usr/lib/jvm/java-21-openjdk ./gradlew :kfe-service:test \
  --tests source.kfe.service.KfeWalletServiceTest \
  --tests source.kfe.application.transaction.KfeTransactionWalletResolverTest
```

Expected: FAIL because service and resolver still use old repository methods and do not reject system-role wallets.

- [ ] **Step 4: Filter listWallets by null system role**

Modify `backend/kerosene/kfe-service/src/main/java/source/kfe/service/KfeWalletService.java`.

Change `listWallets(...)`:

```java
    @Transactional(readOnly = true)
    public List<KfeWalletResponse> listWallets(Long userId) {
        return walletRepository.findByUserIdAndStatusInAndSystemRoleIsNullOrderByCreatedAtDesc(
                        userId,
                        USER_VISIBLE_WALLET_STATUSES)
                .stream()
                .map(responseMapper::toWalletResponse)
                .toList();
    }
```

- [ ] **Step 5: Reject system-role wallets in user transaction resolver**

Modify `backend/kerosene/kfe-service/src/main/java/source/kfe/application/transaction/KfeTransactionWalletResolver.java`.

In `resolveInternalDestinationReference(...)`, after loading the user handle, add:

```java
        if (!user.active()) {
            throw new IllegalArgumentException("Destination user is not active.");
        }
```

Replace destination wallet lookup:

```java
        KfeWalletEntity wallet = walletRepository.findByUserIdAndStatusInAndSystemRoleIsNullOrderByCreatedAtDesc(
                        user.id(),
                        List.of(KfeWalletStatus.ACTIVE))
                .stream()
                .filter(this::isSpendableActiveWallet)
                .findFirst()
                .orElseThrow(() -> new IllegalArgumentException("Destination user has no active KFE wallet."));
```

Add import:

```java
import java.util.List;
```

In `requireSpendable(...)`, add this check before the status check:

```java
        if (wallet.getSystemRole() != null) {
            throw new IllegalStateException(role + " wallet is a system treasury wallet and is not available through user transaction flow.");
        }
```

- [ ] **Step 6: Run focused tests**

Run:

```bash
cd backend/kerosene
JAVA_HOME=/usr/lib/jvm/java-21-openjdk ./gradlew :kfe-service:test \
  --tests source.kfe.service.KfeWalletServiceTest \
  --tests source.kfe.application.transaction.KfeTransactionWalletResolverTest
```

Expected: PASS.

- [ ] **Step 7: Commit Task 4**

```bash
git add \
  backend/kerosene/kfe-service/src/main/java/source/kfe/service/KfeWalletService.java \
  backend/kerosene/kfe-service/src/main/java/source/kfe/application/transaction/KfeTransactionWalletResolver.java \
  backend/kerosene/kfe-service/src/test/java/source/kfe/service/KfeWalletServiceTest.java \
  backend/kerosene/kfe-service/src/test/java/source/kfe/application/transaction/KfeTransactionWalletResolverTest.java
git commit -m "fix: hide treasury wallet from user KFE flows"
```

---

### Task 5: Explicit Treasury Reserve Accounting

**Files:**
- Modify: `backend/kerosene/kfe-service/src/main/java/source/kfe/repository/KfeBalanceRepository.java`
- Modify: `backend/kerosene/kfe-service/src/main/java/source/kfe/repository/KfeWalletRepository.java`
- Modify: `backend/kerosene/kfe-service/src/main/java/source/kfe/dto/KfeReserveOverviewResponse.java`
- Modify: `backend/kerosene/kfe-service/src/main/java/source/kfe/service/KfeReserveOverviewService.java`
- Create: `backend/kerosene/kfe-service/src/test/java/source/kfe/service/KfeReserveOverviewServiceTest.java`

- [ ] **Step 1: Write failing reserve overview test**

Create `backend/kerosene/kfe-service/src/test/java/source/kfe/service/KfeReserveOverviewServiceTest.java`:

```java
package source.kfe.service;

import org.junit.jupiter.api.Test;
import source.kfe.repository.KfeBalanceRepository;
import source.kfe.repository.KfeWalletRepository;
import source.kfe.model.KfeWalletStatus;
import source.kfe.model.KfeWalletSystemRole;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertTrue;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.when;

class KfeReserveOverviewServiceTest {

    private final KfeBalanceRepository balanceRepository = mock(KfeBalanceRepository.class);
    private final KfeWalletRepository walletRepository = mock(KfeWalletRepository.class);
    private final KfeReserveOverviewService service = new KfeReserveOverviewService(balanceRepository, walletRepository);

    @Test
    void overviewReportsTreasuryBalancesExplicitly() {
        when(balanceRepository.totalBtcBalances()).thenReturn(new Totals(500_000L, 100_000L, 50_000L, 25_000L, 10_000L));
        when(balanceRepository.systemTreasuryBtcBalances()).thenReturn(new Totals(300_000L, 40_000L, 20_000L, 5_000L, 0L));
        when(walletRepository.existsBySystemRoleAndStatusIn(
                KfeWalletSystemRole.TREASURY,
                KfeReserveOverviewService.ACTIVE_TREASURY_STATUSES)).thenReturn(true);

        var response = service.overview();

        assertEquals(0.00685, response.totalOnchainBtc());
        assertEquals(0.00365, response.treasuryOnchainBtc());
        assertEquals(0.003, response.treasuryAvailableOnchainBtc());
        assertEquals(0.00025, response.treasuryReservedOnchainBtc());
        assertTrue(response.treasuryWalletActive());
    }

    private record Totals(
            long availableSats,
            long pendingSats,
            long lockedSats,
            long autoHoldSats,
            long observedSats) implements KfeBalanceRepository.BalanceTotals {
    }
}
```

- [ ] **Step 2: Run reserve test and verify it fails**

Run:

```bash
cd backend/kerosene
JAVA_HOME=/usr/lib/jvm/java-21-openjdk ./gradlew :kfe-service:test --tests source.kfe.service.KfeReserveOverviewServiceTest
```

Expected: FAIL because `BalanceTotals`, `totalBtcBalances`, `systemTreasuryBtcBalances`, `KfeReserveOverviewService.ACTIVE_TREASURY_STATUSES`, and treasury response fields do not exist.

- [ ] **Step 3: Add balance projections and queries**

Modify `backend/kerosene/kfe-service/src/main/java/source/kfe/repository/KfeBalanceRepository.java`.

Add projection inside the interface:

```java
    interface BalanceTotals {
        long getAvailableSats();
        long getPendingSats();
        long getLockedSats();
        long getAutoHoldSats();
        long getObservedSats();
    }
```

Add queries:

```java
    @Query(value = """
            SELECT
                COALESCE(SUM(available_sats), 0) AS availableSats,
                COALESCE(SUM(pending_sats), 0) AS pendingSats,
                COALESCE(SUM(locked_sats), 0) AS lockedSats,
                COALESCE(SUM(auto_hold_sats), 0) AS autoHoldSats,
                COALESCE(SUM(observed_sats), 0) AS observedSats
            FROM financial.balances_core
            WHERE asset = 'BTC'
            """, nativeQuery = true)
    BalanceTotals totalBtcBalances();

    @Query(value = """
            SELECT
                COALESCE(SUM(b.available_sats), 0) AS availableSats,
                COALESCE(SUM(b.pending_sats), 0) AS pendingSats,
                COALESCE(SUM(b.locked_sats), 0) AS lockedSats,
                COALESCE(SUM(b.auto_hold_sats), 0) AS autoHoldSats,
                COALESCE(SUM(b.observed_sats), 0) AS observedSats
            FROM financial.wallets_core w
            JOIN financial.balances_core b
              ON b.wallet_id = w.id AND b.asset = w.asset
            WHERE w.system_role = 'TREASURY'
              AND w.status IN ('ACTIVE', 'FROZEN', 'ROTATING_ADDRESS')
              AND b.asset = 'BTC'
            """, nativeQuery = true)
    BalanceTotals systemTreasuryBtcBalances();
```

- [ ] **Step 4: Add active treasury existence query**

Modify `backend/kerosene/kfe-service/src/main/java/source/kfe/repository/KfeWalletRepository.java`.

Add this method:

```java
    boolean existsBySystemRoleAndStatusIn(
            KfeWalletSystemRole systemRole,
            Collection<KfeWalletStatus> statuses);
```

- [ ] **Step 5: Add treasury fields to reserve response**

Modify `backend/kerosene/kfe-service/src/main/java/source/kfe/dto/KfeReserveOverviewResponse.java`.

Replace record fields with:

```java
public record KfeReserveOverviewResponse(
        double totalOnchainBtc,
        double lightningNodeBtc,
        double inboundLiquidityBtc,
        double outboundLiquidityBtc,
        double reservedOnchainBtc,
        double reservedLightningBtc,
        double availableOnchainBtc,
        double availableLightningBtc,
        double treasuryOnchainBtc,
        double treasuryAvailableOnchainBtc,
        double treasuryReservedOnchainBtc,
        boolean treasuryWalletActive,
        boolean lightningSendsAllowed,
        String liquidityState) {
}
```

- [ ] **Step 6: Update reserve service to use explicit totals**

Modify `backend/kerosene/kfe-service/src/main/java/source/kfe/service/KfeReserveOverviewService.java`.

Add imports:

```java
import source.kfe.model.KfeWalletStatus;
import source.kfe.model.KfeWalletSystemRole;
import source.kfe.repository.KfeWalletRepository;

import java.util.List;
```

Add field and constructor dependency:

```java
    public static final List<KfeWalletStatus> ACTIVE_TREASURY_STATUSES = List.of(
            KfeWalletStatus.ACTIVE,
            KfeWalletStatus.FROZEN,
            KfeWalletStatus.ROTATING_ADDRESS);

    private final KfeBalanceRepository balanceRepository;
    private final KfeWalletRepository walletRepository;

    public KfeReserveOverviewService(
            KfeBalanceRepository balanceRepository,
            KfeWalletRepository walletRepository) {
        this.balanceRepository = balanceRepository;
        this.walletRepository = walletRepository;
    }
```

Replace `overview()` with:

```java
    @Transactional(readOnly = true)
    public KfeReserveOverviewResponse overview() {
        KfeBalanceRepository.BalanceTotals totals = balanceRepository.totalBtcBalances();
        KfeBalanceRepository.BalanceTotals treasury = balanceRepository.systemTreasuryBtcBalances();

        long availableSats = totals.getAvailableSats();
        long pendingSats = totals.getPendingSats();
        long reservedSats = totals.getLockedSats() + totals.getAutoHoldSats();
        long observedSats = totals.getObservedSats();
        long totalSats = availableSats + pendingSats + reservedSats + observedSats;

        long treasuryReservedSats = treasury.getLockedSats() + treasury.getAutoHoldSats();
        long treasuryTotalSats = treasury.getAvailableSats()
                + treasury.getPendingSats()
                + treasuryReservedSats
                + treasury.getObservedSats();
        boolean treasuryWalletActive = walletRepository.existsBySystemRoleAndStatusIn(
                KfeWalletSystemRole.TREASURY,
                ACTIVE_TREASURY_STATUSES);

        return new KfeReserveOverviewResponse(
                btc(totalSats), 0.0, 0.0, 0.0,
                btc(reservedSats), 0.0,
                btc(availableSats), 0.0,
                btc(treasuryTotalSats),
                btc(treasury.getAvailableSats()),
                btc(treasuryReservedSats),
                treasuryWalletActive,
                availableSats > 0,
                state(availableSats, reservedSats, observedSats));
    }
```

- [ ] **Step 7: Run reserve test**

Run:

```bash
cd backend/kerosene
JAVA_HOME=/usr/lib/jvm/java-21-openjdk ./gradlew :kfe-service:test --tests source.kfe.service.KfeReserveOverviewServiceTest
```

Expected: PASS.

- [ ] **Step 8: Commit Task 5**

```bash
git add \
  backend/kerosene/kfe-service/src/main/java/source/kfe/repository/KfeBalanceRepository.java \
  backend/kerosene/kfe-service/src/main/java/source/kfe/repository/KfeWalletRepository.java \
  backend/kerosene/kfe-service/src/main/java/source/kfe/dto/KfeReserveOverviewResponse.java \
  backend/kerosene/kfe-service/src/main/java/source/kfe/service/KfeReserveOverviewService.java \
  backend/kerosene/kfe-service/src/test/java/source/kfe/service/KfeReserveOverviewServiceTest.java
git commit -m "feat: report KFE treasury reserve totals"
```

---

### Task 6: Quorum And Secret Boundary Tests

**Files:**
- Modify: `backend/kerosene/kfe-service/src/test/java/source/kfe/application/transaction/KfeSubmitTransactionUseCaseTest.java`
- Modify: `backend/kerosene/kfe-service/src/test/java/source/kfe/service/KfeWalletServiceTest.java`

- [ ] **Step 1: Add transaction quorum proof test**

Modify `backend/kerosene/kfe-service/src/test/java/source/kfe/application/transaction/KfeSubmitTransactionUseCaseTest.java`.

Add this test:

```java
    @Test
    void submitRequiresQuorumBeforeReservingSourceFunds() {
        Long userId = 123L;
        KfeSubmitTransactionRequest request = outboundRequest();
        String requestHash = "request-hash";
        UUID sourceWalletId = request.sourceWalletId();
        source.kfe.model.KfeWalletEntity sourceWallet = new source.kfe.model.KfeWalletEntity();
        sourceWallet.setId(sourceWalletId);
        sourceWallet.setUserId(userId);
        sourceWallet.setKind(source.kfe.model.KfeWalletKind.INTERNAL);
        sourceWallet.setStatus(source.kfe.model.KfeWalletStatus.ACTIVE);
        sourceWallet.setLabel("carteira global");

        source.kfe.model.KfeTransactionEntity tx = new source.kfe.model.KfeTransactionEntity();
        tx.setId(UUID.randomUUID());
        tx.setUserId(userId);
        tx.setRail(KfeRail.ONCHAIN);
        tx.setDirection(KfeDirection.OUTBOUND);
        tx.setSourceWalletId(sourceWalletId);
        tx.setGrossAmountSats(100_000L);
        tx.setTotalDebitSats(101_000L);

        when(walletResolver.resolveInternalDestinationReference(request)).thenReturn(request);
        when(idempotencyUseCase.requestHash(userId, request)).thenReturn(requestHash);
        when(idempotencyUseCase.find(userId, request.idempotencyKey())).thenReturn(null);
        when(idempotencyUseCase.reserve(userId, request, requestHash))
                .thenReturn(mock(source.kfe.model.KfeIdempotencyEntity.class));
        when(transactionRepository.save(org.mockito.ArgumentMatchers.any(source.kfe.model.KfeTransactionEntity.class)))
                .thenReturn(tx);
        when(walletResolver.resolveSourceWallet(userId, request)).thenReturn(sourceWallet);
        when(walletResolver.resolveDestinationWallet(userId, request)).thenReturn(null);
        when(pricingService.quote(KfeRail.ONCHAIN, KfeDirection.OUTBOUND, 100_000L, 1000L))
                .thenReturn(new KfePricingService.Quote(100_000L, 99_000L, 1000L, 0L, 101_000L));
        when(hashService.sha256(org.mockito.ArgumentMatchers.anyString())).thenReturn("proposal-hash");
        when(quorumGateway.requireHealthyUnanimousConsensus("proposal-hash"))
                .thenThrow(new IllegalStateException("quorum unavailable"));

        assertThrows(IllegalStateException.class, () -> useCase.submit(userId, request));

        verify(quorumGateway).requireHealthyUnanimousConsensus("proposal-hash");
        verify(balanceService, never()).reserve(org.mockito.ArgumentMatchers.any(), org.mockito.ArgumentMatchers.any(), org.mockito.ArgumentMatchers.anyLong());
        verify(outboxUseCase, never()).enqueueExternal(org.mockito.ArgumentMatchers.any(), org.mockito.ArgumentMatchers.any());
    }
```

- [ ] **Step 2: Add wallet creation secret-boundary assertion**

Modify `backend/kerosene/kfe-service/src/test/java/source/kfe/service/KfeWalletServiceTest.java`.

In `createSystemTreasuryWalletMarksWalletAsTreasuryAndUsesQuorum()`, add:

```java
        assertEquals(null, persistedWallet.get().getMpcPublicKey());
        assertEquals(null, persistedWallet.get().getXpub());
        assertEquals(null, persistedWallet.get().getDescriptor());
```

- [ ] **Step 3: Run focused quorum tests**

Run:

```bash
cd backend/kerosene
JAVA_HOME=/usr/lib/jvm/java-21-openjdk ./gradlew :kfe-service:test \
  --tests source.kfe.application.transaction.KfeSubmitTransactionUseCaseTest \
  --tests source.kfe.service.KfeWalletServiceTest
```

Expected: PASS.

- [ ] **Step 4: Commit Task 6**

```bash
git add \
  backend/kerosene/kfe-service/src/test/java/source/kfe/application/transaction/KfeSubmitTransactionUseCaseTest.java \
  backend/kerosene/kfe-service/src/test/java/source/kfe/service/KfeWalletServiceTest.java
git commit -m "test: guard KFE treasury quorum boundary"
```

---

### Task 7: Full Verification

**Files:**
- No planned source edits.

- [ ] **Step 1: Run focused backend verification**

Run:

```bash
cd backend/kerosene
JAVA_HOME=/usr/lib/jvm/java-21-openjdk ./gradlew :kfe-service:test test \
  --tests source.architecture.KfeSystemTreasuryWalletMigrationTest \
  --tests source.auth.integration.AuthFinancialSystemPrincipalAdapterTest \
  --tests source.auth.application.service.authentication.LoginValidatorTest \
  --tests source.kfe.service.KfeSystemTreasuryWalletBootstrapperTest \
  --tests source.kfe.service.KfeWalletServiceTest \
  --tests source.kfe.application.transaction.KfeTransactionWalletResolverTest \
  --tests source.kfe.service.KfeReserveOverviewServiceTest \
  --tests source.kfe.application.transaction.KfeSubmitTransactionUseCaseTest
```

Expected: PASS.

- [ ] **Step 2: Run KFE service tests**

Run:

```bash
cd backend/kerosene
JAVA_HOME=/usr/lib/jvm/java-21-openjdk ./gradlew :kfe-service:test
```

Expected: PASS.

- [ ] **Step 3: Run root backend tests**

Run:

```bash
cd backend/kerosene
JAVA_HOME=/usr/lib/jvm/java-21-openjdk ./gradlew test
```

Expected: PASS, unless the existing production guardrail failure for missing `backend/kerosene-infrastructure/prod/k8s/kerosene-app.yaml` is still present. If that existing failure appears, capture the exact failure and do not treat it as caused by the treasury-wallet implementation.

- [ ] **Step 4: Inspect git status**

Run:

```bash
git status --short
```

Expected: only unrelated pre-existing worktree changes remain outside the treasury-wallet commits.

- [ ] **Step 5: Final implementation summary**

Report:

- Commit hashes created for Tasks 1-6.
- Exact verification commands and pass/fail results.
- Any pre-existing root test failure that remains outside this implementation.
