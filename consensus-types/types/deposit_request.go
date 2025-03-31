package types

import (
	"fmt"

	"github.com/berachain/beacon-kit/primitives/eip7685"
)

const MaxDepositRequestsPerPayload = 8192

// DepositRequest is introduced in EIP6110 which is currently not processed.
type DepositRequest = Deposit

// DepositRequests is used for SSZ unmarshalling a list of DepositRequest
type DepositRequests []*DepositRequest

// MarshalSSZ marshals the Deposits object to SSZ format by encoding each deposit individually.
func (dr *DepositRequests) MarshalSSZ() ([]byte, error) {
	return eip7685.MarshalItems[*DepositRequest](*dr)
}

// DecodeDepositRequests decodes SSZ data by decoding each request individually.
func DecodeDepositRequests(data []byte) (DepositRequests, error) {
	maxSize := MaxDepositRequestsPerPayload * DepositSize
	if len(data) > maxSize {
		return nil, fmt.Errorf(
			"invalid deposit requests SSZ size, requests should not be more than the max per "+
				"payload, got %d max %d", len(data), maxSize,
		)
	}
	if len(data) < DepositSize {
		return nil, fmt.Errorf("invalid deposit requests SSZ size, got %d expected at least %d", len(data), DepositSize)
	}
	// Use the generic unmarshalItems helper.
	items, err := eip7685.UnmarshalItems[*DepositRequest](data, DepositSize, func() *Deposit { return new(DepositRequest) })
	if err != nil {
		return nil, err
	}
	deposits := DepositRequests(items)
	return deposits, nil
}
