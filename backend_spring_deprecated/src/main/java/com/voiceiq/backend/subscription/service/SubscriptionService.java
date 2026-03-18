package com.voiceiq.backend.subscription.service;

import com.voiceiq.backend.auth.domain.PlanType;
import com.voiceiq.backend.auth.domain.User;
import com.voiceiq.backend.auth.repository.UserRepository;
import com.voiceiq.backend.auth.security.CurrentUserService;
import com.voiceiq.backend.common.exception.BadRequestException;
import com.voiceiq.backend.common.exception.NotFoundException;
import com.voiceiq.backend.config.DeveloperAccessProperties;
import com.voiceiq.backend.config.PlanLimitsProperties;
import com.voiceiq.backend.subscription.domain.Subscription;
import com.voiceiq.backend.subscription.domain.SubscriptionProvider;
import com.voiceiq.backend.subscription.domain.SubscriptionStatus;
import com.voiceiq.backend.subscription.domain.UsageCounter;
import com.voiceiq.backend.subscription.dto.SubscriptionSummaryResponse;
import com.voiceiq.backend.subscription.repository.SubscriptionRepository;
import com.voiceiq.backend.subscription.repository.UsageCounterRepository;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDateTime;
import java.time.YearMonth;
import java.util.UUID;

@Service
public class SubscriptionService {

    private final SubscriptionRepository subscriptionRepository;
    private final UsageCounterRepository usageCounterRepository;
    private final PlanLimitsProperties planLimitsProperties;
    private final DeveloperAccessProperties developerAccessProperties;
    private final CurrentUserService currentUserService;
    private final UserRepository userRepository;

    public SubscriptionService(
            SubscriptionRepository subscriptionRepository,
            UsageCounterRepository usageCounterRepository,
            PlanLimitsProperties planLimitsProperties,
            DeveloperAccessProperties developerAccessProperties,
            CurrentUserService currentUserService,
            UserRepository userRepository
    ) {
        this.subscriptionRepository = subscriptionRepository;
        this.usageCounterRepository = usageCounterRepository;
        this.planLimitsProperties = planLimitsProperties;
        this.developerAccessProperties = developerAccessProperties;
        this.currentUserService = currentUserService;
        this.userRepository = userRepository;
    }

    @Transactional
    public Subscription ensureSubscription(User user) {
        Subscription subscription = subscriptionRepository.findByUser_Id(user.getId())
                .orElseGet(() -> createDefaultSubscription(user));
        return applyDeveloperOverride(user, subscription);
    }

    @Transactional
    public void assertSessionCreationAllowed(User user) {
        if (isDeveloperAccount(user)) {
            return;
        }

        Subscription subscription = ensureSubscription(user);
        UsageCounter usageCounter = currentUsage(user);
        int sessionLimit = sessionLimit(subscription.getPlan());
        if (usageCounter.getSessionsUsed() >= sessionLimit) {
            throw new BadRequestException("Monthly session quota exceeded for the current plan");
        }
    }

    @Transactional
    public void recordSessionCreated(User user) {
        UsageCounter usageCounter = currentUsage(user);
        usageCounter.setSessionsUsed(usageCounter.getSessionsUsed() + 1);
        usageCounterRepository.save(usageCounter);
    }

    @Transactional
    public void assertProcessingAllowed(User user, int durationSeconds) {
        if (isDeveloperAccount(user)) {
            return;
        }

        Subscription subscription = ensureSubscription(user);
        UsageCounter usageCounter = currentUsage(user);
        int secondLimit = processedSecondsLimit(subscription.getPlan());
        if (usageCounter.getProcessedSeconds() + durationSeconds > secondLimit) {
            throw new BadRequestException("Monthly audio processing quota exceeded for the current plan");
        }
    }

    @Transactional
    public void recordProcessedSeconds(User user, int durationSeconds) {
        UsageCounter usageCounter = currentUsage(user);
        usageCounter.setProcessedSeconds(usageCounter.getProcessedSeconds() + durationSeconds);
        usageCounterRepository.save(usageCounter);
    }

    @Transactional
    public SubscriptionSummaryResponse getCurrentSummary() {
        UUID userId = currentUserService.requireCurrentUser().userId();
        User user = userRepository.findById(userId)
                .orElseThrow(() -> new NotFoundException("User not found"));
        Subscription subscription = ensureSubscription(user);
        UsageCounter usageCounter = currentUsage(subscription.getUser());

        boolean developerAccount = isDeveloperAccount(user);
        int sessionLimit = developerAccount ? Integer.MAX_VALUE : sessionLimit(subscription.getPlan());
        int secondLimit = developerAccount ? Integer.MAX_VALUE : processedSecondsLimit(subscription.getPlan());

        return new SubscriptionSummaryResponse(
                userId,
                subscription.getPlan(),
                subscription.getStatus(),
                subscription.getProvider(),
                developerAccount,
                subscription.getCurrentPeriodStart(),
                subscription.getCurrentPeriodEnd(),
                usageCounter.getSessionsUsed(),
                sessionLimit,
                Math.max(0, sessionLimit - usageCounter.getSessionsUsed()),
                usageCounter.getProcessedSeconds(),
                secondLimit,
                Math.max(0, secondLimit - usageCounter.getProcessedSeconds())
        );
    }

    @Transactional
    public UsageCounter currentUsage(User user) {
        YearMonth currentMonth = YearMonth.now();
        LocalDateTime periodStart = currentMonth.atDay(1).atStartOfDay();
        LocalDateTime periodEnd = currentMonth.plusMonths(1).atDay(1).atStartOfDay().minusSeconds(1);

        return usageCounterRepository.findByUser_IdAndPeriodStartAndPeriodEnd(user.getId(), periodStart, periodEnd)
                .orElseGet(() -> {
                    UsageCounter usageCounter = new UsageCounter();
                    usageCounter.setId(UUID.randomUUID());
                    usageCounter.setUser(user);
                    usageCounter.setPeriodStart(periodStart);
                    usageCounter.setPeriodEnd(periodEnd);
                    usageCounter.setSessionsUsed(0);
                    usageCounter.setProcessedSeconds(0);
                    return usageCounterRepository.save(usageCounter);
                });
    }

    private Subscription createDefaultSubscription(User user) {
        YearMonth currentMonth = YearMonth.now();
        Subscription subscription = new Subscription();
        subscription.setId(UUID.randomUUID());
        subscription.setUser(user);
        subscription.setPlan(user.getPlan());
        subscription.setStatus(SubscriptionStatus.ACTIVE);
        subscription.setProvider(SubscriptionProvider.INTERNAL);
        subscription.setCurrentPeriodStart(currentMonth.atDay(1).atStartOfDay());
        subscription.setCurrentPeriodEnd(currentMonth.plusMonths(1).atDay(1).atStartOfDay().minusSeconds(1));
        return subscriptionRepository.save(subscription);
    }

    @Transactional
    public User applyDeveloperPlan(User user) {
        if (!isDeveloperAccount(user) || user.getPlan() == PlanType.PRO) {
            return user;
        }

        user.setPlan(PlanType.PRO);
        return userRepository.save(user);
    }

    public boolean isDeveloperAccount(User user) {
        if (user == null || user.getEmail() == null) {
            return false;
        }
        return developerAccessProperties.emails().contains(user.getEmail().trim().toLowerCase());
    }

    private Subscription applyDeveloperOverride(User user, Subscription subscription) {
        if (!isDeveloperAccount(user)) {
            return subscription;
        }

        boolean subscriptionChanged = false;
        if (user.getPlan() != PlanType.PRO) {
            user.setPlan(PlanType.PRO);
            userRepository.save(user);
        }
        if (subscription.getPlan() != PlanType.PRO) {
            subscription.setPlan(PlanType.PRO);
            subscriptionChanged = true;
        }
        if (subscription.getStatus() != SubscriptionStatus.ACTIVE) {
            subscription.setStatus(SubscriptionStatus.ACTIVE);
            subscriptionChanged = true;
        }
        if (subscription.getProvider() != SubscriptionProvider.INTERNAL) {
            subscription.setProvider(SubscriptionProvider.INTERNAL);
            subscriptionChanged = true;
        }

        LocalDateTime lifetimeStart = LocalDateTime.of(2026, 1, 1, 0, 0);
        LocalDateTime lifetimeEnd = LocalDateTime.of(2099, 12, 31, 23, 59, 59);
        if (!lifetimeStart.equals(subscription.getCurrentPeriodStart())) {
            subscription.setCurrentPeriodStart(lifetimeStart);
            subscriptionChanged = true;
        }
        if (!lifetimeEnd.equals(subscription.getCurrentPeriodEnd())) {
            subscription.setCurrentPeriodEnd(lifetimeEnd);
            subscriptionChanged = true;
        }

        return subscriptionChanged ? subscriptionRepository.save(subscription) : subscription;
    }

    private int sessionLimit(PlanType planType) {
        return switch (planType) {
            case FREE -> planLimitsProperties.free().monthlySessions();
            case PRO -> planLimitsProperties.pro().monthlySessions();
        };
    }

    private int processedSecondsLimit(PlanType planType) {
        return switch (planType) {
            case FREE -> planLimitsProperties.free().monthlyProcessedSeconds();
            case PRO -> planLimitsProperties.pro().monthlyProcessedSeconds();
        };
    }
}
